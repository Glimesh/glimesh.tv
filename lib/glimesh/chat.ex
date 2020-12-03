defmodule Glimesh.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false

  alias Glimesh.Accounts.User
  alias Glimesh.Chat.ChatMessage
  alias Glimesh.Repo
  alias Glimesh.Streams
  alias Glimesh.Streams.Channel
  alias Glimesh.Streams.ChannelBan
  alias Glimesh.Streams.ChannelModerationLog
  alias Glimesh.Streams.ChannelModerator

  defdelegate authorize(action, user, params), to: Glimesh.Chat.Policy

  # User API Calls

  @doc """
  Creates a chat_message.

  ## Examples

      iex> create_chat_message(%User{}, %Channel{}, %{field: value})
      {:ok, %ChatMessage{}}

      iex> create_chat_message(%User{}, %Channel{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat_message(%User{} = user, %Channel{} = channel, attrs \\ %{}) do
    with :ok <- Bodyguard.permit(__MODULE__, :create_chat_message, user, channel) do
      if allow_link_in_message(channel, attrs) do
        %ChatMessage{
          channel: channel,
          user: user
        }
        |> ChatMessage.changeset(attrs)
        |> Repo.insert()
        |> broadcast(:chat_message)
      else
        {:error, "This channel has links disabled!"}
      end
    end
  end

  @doc """
  Short timeout (5 minutes) a user from a chat channel.

  ## Examples

      iex> short_timeout_user(%User{} = moderator, %Channel{} = channel, %User{})
      {:ok, %ChannelModerationLog{}}

  """
  def short_timeout_user(%User{} = moderator, %Channel{} = channel, %User{} = user_to_timeout) do
    with :ok <- Bodyguard.permit(__MODULE__, :short_timeout, moderator, channel) do
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
  end

  @doc """
  Long timeout (15 minutes) a user from a chat channel.

  ## Examples

      iex> long_timeout_user(%User{} = moderator, %Channel{} = channel, %User{})
      {:ok, %ChannelModerationLog{}}

  """
  def long_timeout_user(%User{} = moderator, %Channel{} = channel, %User{} = user_to_timeout) do
    with :ok <- Bodyguard.permit(__MODULE__, :long_timeout, moderator, channel) do
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
  end

  @doc """
  Ban a user permanently from a chat channel.

  ## Examples

      iex> ban_user(%User{} = moderator, %Channel{} = channel, %User{})
      {:ok, %ChannelModerationLog{}}

  """
  def ban_user(%User{} = moderator, %Channel{} = channel, %User{} = user_to_ban) do
    with :ok <- Bodyguard.permit(__MODULE__, :ban, moderator, channel) do
      ban_user_until(channel, user_to_ban, nil)

      %ChannelModerationLog{
        channel: channel,
        moderator: moderator,
        user: user_to_ban
      }
      |> ChannelModerationLog.changeset(%{action: "ban"})
      |> Repo.insert()
    end
  end

  @doc """
  Unban a user from a chat channel.

  ## Examples

      iex> unban_user(%User{} = moderator, %Channel{} = channel, %User{})
      {:ok, %ChannelModerationLog{}}

  """
  def unban_user(%User{} = moderator, %Channel{} = channel, %User{} = user_to_unban) do
    with :ok <- Bodyguard.permit(__MODULE__, :unban, moderator, channel) do
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
  end

  # System API Calls

  @doc """
  Returns the list of chat_messages.

  ## Examples

      iex> list_chat_messages()
      [%ChatMessage{}, ...]

  """
  def list_chat_messages(channel, limit \\ 5) do
    Repo.all(
      from m in ChatMessage,
        where: m.is_visible == true and m.channel_id == ^channel.id,
        order_by: [desc: :inserted_at],
        limit: ^limit
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

  def allow_link_in_message(%Channel{} = channel, attrs) do
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
    %{
      can_short_timeout: Bodyguard.permit?(__MODULE__, :short_timeout, user, channel),
      can_long_timeout: Bodyguard.permit?(__MODULE__, :long_timeout, user, channel),
      can_ban: Bodyguard.permit?(__MODULE__, :ban, user, channel),
      can_unban: Bodyguard.permit?(__MODULE__, :unban, user, channel)
    }
  end

  @doc """
  is_moderator?/2 controls any views we use to show mod badging, but is not responsible for permissions
  """
  def is_moderator?(nil, nil), do: false
  def is_moderator?(_channel, nil), do: false

  def is_moderator?(channel, user) do
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

  def can_moderate?(action, %Channel{} = channel, %User{} = user) do
    moderator =
      Repo.one(
        from m in ChannelModerator,
          where: m.channel_id == ^channel.id and m.user_id == ^user.id
      )

    if moderator do
      possibly_nil = Map.get(moderator, action, false)
      if is_nil(possibly_nil), do: false, else: possibly_nil
    else
      false
    end
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

  # Private Calls

  defp ban_user_until(%Channel{} = channel, %User{} = user, until) do
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

  defp delete_chat_messages_for_user(%Channel{} = channel, %User{} = user) do
    query =
      from m in ChatMessage,
        where:
          m.is_visible == true and
            m.channel_id == ^channel.id and
            m.user_id == ^user.id

    Repo.update_all(query, set: [is_visible: false])
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

  defp broadcast_timeout({:ok, channel_id, bad_user}, :user_timedout) do
    Glimesh.Events.broadcast(
      Streams.get_subscribe_topic(:chat, channel_id),
      Streams.get_subscribe_topic(:chat),
      :user_timedout,
      bad_user
    )

    {:ok, bad_user}
  end
end
