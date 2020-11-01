defmodule Glimesh.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  import GlimeshWeb.Gettext

  alias Glimesh.Accounts.User
  alias Glimesh.Chat.ChatMessage
  alias Glimesh.Repo
  alias Glimesh.Streams
  alias Glimesh.Streams.Channel
  alias Glimesh.Streams.ChannelBan
  alias Glimesh.Streams.ChannelModerationLog
  alias Phoenix.HTML.Tag

  @doc """
  Returns the list of chat_messages.

  ## Examples

      iex> list_chat_messages()
      [%ChatMessage{}, ...]

  """
  def list_chat_messages(channel) do
    Repo.all(
      from m in ChatMessage,
        where: m.is_visible == true and m.channel_id == ^channel.id,
        order_by: [desc: :inserted_at],
        limit: 5
    )
    |> Repo.preload([:user, :channel])
    |> Enum.reverse()
  end

  @doc """
  Returns the list of chat_messages.

  ## Examples

      iex> list_chat_messages()
      [%ChatMessage{}, ...]

  """
  def list_chat_user_messages(channel, user) do
    Repo.all(
      from m in ChatMessage,
        where:
          m.is_visible == true and
            m.channel_id == ^channel.id and
            m.user_id == ^user.id,
        order_by: [desc: :inserted_at]
    )
    |> Repo.preload([:user, :channel])
    |> Enum.reverse()
  end

  @doc """
  Gets a single chat_message.

  Raises `Ecto.NoResultsError` if the Chat message does not exist.

  ## Examples

      iex> get_chat_message!(123)
      %ChatMessage{}

      iex> get_chat_message!(456)
      ** (Ecto.NoResultsError)

  """
  def get_chat_message!(id), do: Repo.get!(ChatMessage, id) |> Repo.preload([:user, :channel])

  @doc """
  Creates a chat_message.

  ## Examples

      iex> create_chat_message(%{field: value})
      {:ok, %ChatMessage{}}

      iex> create_chat_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat_message(%Channel{} = channel, user, attrs \\ %{}) do
    cond do
      # Specific Channel Ban
      expiry = is_banned_until(channel, user) ->
        if expiry == :infinity do
          throw_error_on_chat(gettext("You are permanently banned from this channel."), attrs)
        else
          seconds = NaiveDateTime.diff(expiry, NaiveDateTime.utc_now(), :second)

          throw_error_on_chat(
            gettext("You are banned from this channel for %{minutes} more minutes.",
              minutes: round(Float.ceil(seconds / 60))
            ),
            attrs
          )
        end

      # Global Account Ban
      Glimesh.Accounts.is_user_banned?(user) ->
        throw_error_on_chat(gettext("You are banned from Glimesh."), attrs)

      # If this message has a link, and it's not allowed in chat
      !allow_link_in_message(channel, attrs) ->
        throw_error_on_chat(gettext("This channel has links disabled!"), attrs)

      # Finally allow them to create a message
      true ->
        %ChatMessage{
          channel: channel,
          user: user
        }
        |> ChatMessage.changeset(attrs)
        |> Repo.insert()
        |> broadcast(:chat_message)
    end
  end

  @doc """
  Updates a chat_message.

  ## Examples

      iex> update_chat_message(chat_message, %{field: new_value})
      {:ok, %ChatMessage{}}

      iex> update_chat_message(chat_message, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_chat_message(%ChatMessage{} = chat_message, attrs) do
    chat_message
    |> ChatMessage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a chat_message.

  ## Examples

      iex> delete_chat_message(chat_message)
      {:ok, %ChatMessage{}}

      iex> delete_chat_message(chat_message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chat_message(%ChatMessage{} = chat_message) do
    chat_message
    |> ChatMessage.changeset(%{is_visible: false})
    |> Repo.update()
  end

  @doc """
  Deletes chat messages for user.

  ## Examples

      iex> delete_chat_messages_for_user(chat_message)
      {:ok, %ChatMessage{}}

      iex> delete_chat_messages_for_user(chat_message)
      {:error, %Ecto.Changeset{}}

  """
  def delete_chat_messages_for_user(%Channel{} = channel, %User{} = user) do
    query =
      from m in ChatMessage,
        where:
          m.is_visible == true and
            m.channel_id == ^channel.id and
            m.user_id == ^user.id

    Repo.update_all(query, set: [is_visible: false])
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking chat_message changes.

  ## Examples

      iex> change_chat_message(chat_message)
      %Ecto.Changeset{data: %ChatMessage{}}

  """
  def change_chat_message(%ChatMessage{} = chat_message, attrs \\ %{}) do
    ChatMessage.changeset(chat_message, attrs)
  end

  def empty_chat_message do
    ChatMessage.changeset(%ChatMessage{}, %{})
  end

  def get_chat_parser_config(%Channel{} = channel) do
    %Glimesh.Chat.Parser.Config{
      allow_links: !channel.disable_hyperlinks,
      allow_glimojis: true
    }
  end

  alias Glimesh.Streams.ChannelModerator

  @doc """
  get_moderator_permissions/2 is used to control the UI, and should not be used to do the final permission check
  """
  def get_moderator_permissions(_channel, nil),
    do: %{
      can_short_timeout: false,
      can_long_timeout: false,
      can_ban: false
    }

  def get_moderator_permissions(%Channel{} = channel, %User{} = user) do
    super_perms = user.is_admin || channel.user_id == user.id

    case Repo.one(
           from m in ChannelModerator,
             where: m.channel_id == ^channel.id and m.user_id == ^user.id
         ) do
      nil ->
        %{
          can_short_timeout: super_perms,
          can_long_timeout: super_perms,
          can_ban: super_perms
        }

      mod ->
        Map.take(mod, [:can_short_timeout, :can_long_timeout, :can_ban])
    end
  end

  @doc """
  is_moderator?/2 controls any views we use to show mod badging, but is not responsible for permissions
  """
  def is_moderator?(nil, nil), do: false
  def is_moderator?(_channel, nil), do: false

  def is_moderator?(channel, user) do
    user.is_admin || channel.user_id == user.id ||
      Repo.exists?(
        from m in ChannelModerator,
          where: m.channel_id == ^channel.id and m.user_id == ^user.id
      )
  end

  @doc """
  can_moderate?/3 is responsible for the final check of a mod permission before an action is taken
  """
  def can_moderate?(_action, nil, nil), do: false
  def can_moderate?(_action, _channel, nil), do: false

  def can_moderate?(action, channel, user) do
    moderator =
      Repo.one(
        from m in ChannelModerator,
          where: m.channel_id == ^channel.id and m.user_id == ^user.id
      )

    if moderator do
      Map.get(moderator, action, false)
    else
      user.is_admin || channel.user_id == user.id
    end
  end

  def short_timeout_user(%Channel{} = channel, %User{} = moderator, user_to_timeout) do
    if can_moderate?(:can_short_timeout, channel, moderator) === false do
      raise "User does not have permission to moderate."
    end

    five_minutes = NaiveDateTime.add(NaiveDateTime.utc_now(), 5 * 60, :second)
    ban_user_until(channel, user_to_timeout, five_minutes)

    %ChannelModerationLog{
      channel: channel,
      moderator: moderator,
      user: user_to_timeout
    }
    |> ChannelModerationLog.changeset(%{action: "short_timeout"})
    |> Repo.insert()
  end

  def long_timeout_user(%Channel{} = channel, %User{} = moderator, user_to_timeout) do
    if can_moderate?(:can_long_timeout, channel, moderator) === false do
      raise "User does not have permission to moderate."
    end

    fifteen_minutes = NaiveDateTime.add(NaiveDateTime.utc_now(), 15 * 60, :second)
    ban_user_until(channel, user_to_timeout, fifteen_minutes)

    %ChannelModerationLog{
      channel: channel,
      moderator: moderator,
      user: user_to_timeout
    }
    |> ChannelModerationLog.changeset(%{action: "long_timeout"})
    |> Repo.insert()
  end

  def ban_user(%Channel{} = channel, %User{} = moderator, user_to_ban) do
    if can_moderate?(:can_ban, channel, moderator) === false do
      raise "User does not have permission to moderate."
    end

    ban_user_until(channel, user_to_ban, nil)

    %ChannelModerationLog{
      channel: channel,
      moderator: moderator,
      user: user_to_ban
    }
    |> ChannelModerationLog.changeset(%{action: "ban"})
    |> Repo.insert()
  end

  def unban_user(%Channel{} = channel, %User{} = moderator, %User{} = user_to_unban) do
    if can_moderate?(:can_unban, channel, moderator) === false do
      raise "User does not have permission to moderate."
    end

    Repo.one(
      from m in ChannelBan,
        where:
          m.channel_id == ^channel.id and
            m.user_id == ^user_to_unban.id and
            is_nil(m.expires_at)
    )
    |> Repo.delete!()

    %ChannelModerationLog{
      channel: channel,
      moderator: moderator,
      user: user_to_unban
    }
    |> ChannelModerationLog.changeset(%{action: "unban"})
    |> Repo.insert()
  end

  defp ban_user_until(channel, user, until) do
    %ChannelBan{
      channel: channel,
      user: user
    }
    |> ChannelBan.changeset(%{expires_at: until})
    |> Repo.insert()

    delete_chat_messages_for_user(channel, user)

    broadcast_timeout({:ok, channel.id, user}, :user_timedout)

    {:ok, until}
  end

  @doc """
  Returns false if user is not banned, the expiry time if they are timed out, and :infinity if they are banned.
  """
  def is_banned_until(channel, user) do
    now = NaiveDateTime.utc_now()

    banned_query =
      Repo.one(
        from m in ChannelBan,
          select: [m.id, m.expires_at],
          where: m.channel_id == ^channel.id and m.user_id == ^user.id,
          where: m.expires_at > ^now or is_nil(m.expires_at)
      )

    # Basically, if no row, they are not banned, if row exists return the potentially :infinity until time.
    case banned_query do
      nil -> false
      [_id, nil] -> :infinity
      [_id, until] -> until
    end
  end

  def can_create_chat_message?(%Channel{} = channel, %User{} = user) do
    is_banned_until(channel, user) == false
  end

  def allow_link_in_message(channel, attrs) do
    # Need to add this since phoenix likes strings and our tests don't use them :)
    message_contain_link_helper =
      if attrs["message"] do
        Glimesh.Chat.Parser.message_contains_link(attrs["message"])
      else
        if attrs.message,
          do: Glimesh.Chat.Parser.message_contains_link(attrs.message),
          else: [true]
      end

    case message_contain_link_helper do
      [true] -> !channel.block_links
      _ -> true
    end
  end

  def render_global_badge(user) do
    if user.is_admin do
      Tag.content_tag(:span, "Team Glimesh", class: "badge badge-danger")
    else
      ""
    end
  end

  def render_stream_badge(stream, user) do
    if is_moderator?(stream, user) and user.is_admin === false do
      Tag.content_tag(:span, "Moderator", class: "badge badge-info")
    else
      ""
    end
  end

  def user_in_message(nil, _msg) do
    false
  end

  def user_in_message(user, chat_message) do
    username = user.username

    !(username == chat_message.user.username) &&
      (String.match?(chat_message.message, ~r/\b#{username}\b/i) ||
         String.match?(chat_message.message, ~r/\b#{"@" <> username}\b/i))
  end

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, chat_message}, event) do
    Glimesh.Events.broadcast(
      Streams.get_subscribe_topic(:chat, chat_message.channel_id),
      Streams.get_subscribe_topic(:chat),
      event,
      chat_message
    )

    {:ok, chat_message}
  end

  defp broadcast_timeout({:error, _reason} = error, _event), do: error

  defp broadcast_timeout({:ok, channel_id, bad_user}, :user_timedout) do
    Glimesh.Events.broadcast(
      Streams.get_subscribe_topic(:chat, channel_id),
      Streams.get_subscribe_topic(:chat),
      :user_timedout,
      bad_user
    )

    {:ok, bad_user}
  end

  def throw_error_on_chat(error_message, attrs) do
    {:error,
     %Ecto.Changeset{
       action: :validate,
       changes: %{message: attrs["message"]},
       errors: [
         message: {error_message, [validation: :required]}
       ],
       data: %Glimesh.Chat.ChatMessage{},
       valid?: false
     }}
  end
end
