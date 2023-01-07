defmodule Glimesh.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false

  alias Glimesh.Accounts.User
  alias Glimesh.Chat.ChatMessage
  alias Glimesh.Events
  alias Glimesh.Payments
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
        channel_subscriber = Payments.is_subscribed?(channel, user)
        platform_subscriber = Payments.is_platform_subscriber?(user)

        config =
          Glimesh.Chat.get_chat_parser_config(
            channel,
            platform_subscriber,
            user.id
          )

        %ChatMessage{
          channel: channel,
          user: user,
          metadata: %ChatMessage.Metadata{
            subscriber: channel_subscriber,
            streamer: channel.streamer_id == user.id,
            moderator: Glimesh.Chat.is_moderator?(channel, user),
            admin: user.is_admin,
            platform_founder_subscriber: Payments.is_platform_founder_subscriber?(user),
            platform_supporter_subscriber: Payments.is_platform_supporter_subscriber?(user)
          }
        }
        |> ChatMessage.changeset(attrs)
        |> ChatMessage.put_tokens(config)
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

  def delete_message(
        %User{} = moderator,
        %Channel{} = channel,
        %User{} = message_author,
        message
      ) do
    with :ok <- Bodyguard.permit(__MODULE__, :delete, moderator, channel) do
      delete_chat_message(message)
      broadcast_delete({:ok, message}, :message_deleted)

      %ChannelModerationLog{
        channel: channel,
        moderator: moderator,
        user: message_author
      }
      |> ChannelModerationLog.changeset(%{action: "delete_message"})
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
    Repo.replica().all(
      from m in ChatMessage,
        where: m.is_visible == true and m.channel_id == ^channel.id,
        order_by: [desc: :inserted_at],
        limit: ^limit
    )
    |> Repo.preload([:user, :channel])
    |> Enum.reverse()
  end

  @doc """
  Returns only recent chat messages.

  ## Examples

      iex> list_recent_chat_messages()
      [%ChatMessage{}, ...]

  """
  def list_recent_chat_messages(channel, limit \\ 5) do
    timeframe = NaiveDateTime.add(NaiveDateTime.utc_now(), -(60 * 60), :second)

    Repo.replica().all(
      from m in ChatMessage,
        where:
          m.is_visible == true and
            m.channel_id == ^channel.id and
            m.inserted_at >= ^timeframe,
        order_by: [desc: :inserted_at],
        limit: ^limit
    )
    |> Repo.preload([:user, :channel])
    |> Enum.reverse()
  end

  def list_recent_chatters(channel, hours \\ 2) do
    timeframe = NaiveDateTime.add(NaiveDateTime.utc_now(), hours * -60 * 60, :second)

    from(m in ChatMessage,
      where: m.is_visible == true,
      where: m.channel_id == ^channel.id,
      where: m.inserted_at >= ^timeframe,
      order_by: [desc: m.inserted_at],
      distinct: m.user_id,
      select: m.user_id,
      limit: 5
    )
    |> Repo.replica().all()
  end

  def get_recent_chatters_username_autocomplete(channel, partial_usernames, hours \\ 2) do
    possible_usernames = get_recent_chatters_that_are_present(channel, hours)

    Enum.reject(
      Enum.map(possible_usernames, fn user ->
        if not is_nil(user) do
          find_user_partial_match(user, partial_usernames)
        end
      end),
      fn item -> is_nil(item) end
    )
  end

  @doc """
  Returns a list of all chat_messages in a channel
  """
  def list_all_chat_messages(channel) do
    ChatMessage
    |> order_by(desc: :inserted_at)
    |> where([cm], cm.channel_id == ^channel.id)
    |> preload([:user, :channel])
  end

  @doc """
  Returns a list of all chat_messages for a user
  """
  def list_all_chat_messages_for_user(user) do
    ChatMessage
    |> order_by(desc: :inserted_at)
    |> where([cm], cm.user_id == ^user.id)
    |> preload([:user, :channel])
  end

  @doc """
  Returns a list of all chat_messages for a user
  """
  def list_some_chat_messages_for_user(user, limit \\ 10) do
    ChatMessage
    |> order_by(desc: :inserted_at)
    |> where([cm], cm.user_id == ^user.id)
    |> limit(^limit)
    |> preload([:user, channel: [:streamer]])
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
  def get_chat_message!(id),
    do: Repo.replica().get!(ChatMessage, id) |> Repo.preload([:user, :channel])

  @doc """
  Gets the latest follower message from a channel for a user
  """
  def get_follow_chat_message_for_user(channel, user) do
    Repo.one(
      from m in ChatMessage,
        where:
          m.channel_id == ^channel.id and m.user_id == ^user.id and m.is_followed_message == true,
        order_by: [desc: :inserted_at],
        limit: 1
    )
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
    ChatMessage.changeset(%ChatMessage{}, %{
      # Ensures that the ChatMessage is always replaced in the DOM, even if the message content doesn't change.
      # Specifically used when posting a new message in chat.
      fake_now_property: NaiveDateTime.utc_now()
    })
  end

  def get_chat_parser_config(%Channel{} = channel, allow_animated_emotes \\ false, userid) do
    %Glimesh.Chat.Parser.Config{
      allow_links: !channel.disable_hyperlinks,
      allow_emotes: true,
      allow_animated_emotes: allow_animated_emotes,
      channel_id: channel.id,
      user_id: userid
    }
  end

  def allow_link_in_message(%Channel{} = channel, attrs) do
    # Need to add this since phoenix likes strings and our tests don't use them :)
    message = if attrs["message"], do: attrs["message"], else: attrs.message

    # Dumb fast check to see if there's something that smells like a link
    # If the channel has links disabled it still won't do anything
    if is_bitstring(message) and String.contains?(message, "http") and
         String.contains?(message, "://") do
      !channel.block_links
    else
      true
    end
  end

  @doc """
  get_moderator_permissions/2 is used to control the UI, and should not be used to do the final permission check
  """
  def get_moderator_permissions(_channel, nil),
    do: %{
      can_short_timeout: false,
      can_long_timeout: false,
      can_ban: false,
      can_delete: false
    }

  def get_moderator_permissions(%Channel{} = channel, %User{} = user) do
    %{
      can_short_timeout: Bodyguard.permit?(__MODULE__, :short_timeout, user, channel),
      can_long_timeout: Bodyguard.permit?(__MODULE__, :long_timeout, user, channel),
      can_ban: Bodyguard.permit?(__MODULE__, :ban, user, channel),
      can_unban: Bodyguard.permit?(__MODULE__, :unban, user, channel),
      can_delete: Bodyguard.permit?(__MODULE__, :delete, user, channel)
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

  defp delete_chat_message(%ChatMessage{} = chat_message) do
    chat_message
    |> ChatMessage.changeset(%{is_visible: false})
    |> Repo.update()
  end

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, chat_message}, event) do
    Events.broadcast(
      Streams.get_subscribe_topic(:chat, chat_message.channel_id),
      Streams.get_subscribe_topic(:chat),
      event,
      chat_message
    )

    {:ok, chat_message}
  end

  defp broadcast_timeout({:ok, channel_id, bad_user}, :user_timedout) do
    Events.broadcast(
      Streams.get_subscribe_topic(:chat, channel_id),
      Streams.get_subscribe_topic(:chat),
      :user_timedout,
      bad_user
    )

    {:ok, bad_user}
  end

  defp broadcast_delete({:ok, chat_message}, :message_deleted) do
    Events.broadcast(
      Streams.get_subscribe_topic(:chat, chat_message.channel_id),
      Streams.get_subscribe_topic(:chat),
      :message_deleted,
      chat_message.id
    )
  end

  defp get_recent_chatters_that_are_present(channel, hours) do
    suggestions = list_recent_chatters(channel, hours)

    Enum.map(
      Glimesh.Presence.list_presences(Glimesh.Streams.get_subscribe_topic(:chatters, channel.id)),
      fn data ->
        find_suggestion_match(suggestions, data)
      end
    )
  end

  defp find_user_partial_match(user, partial_usernames) do
    working_partial_username =
      Enum.find(partial_usernames, fn name ->
        String.starts_with?(user, name) and user !== name
      end)

    if not is_nil(working_partial_username),
      do: %{suggestion: user, partial: working_partial_username}
  end

  defp find_suggestion_match(suggestions, data) do
    if Enum.any?(suggestions, fn item -> data[:user_id] == item end) do
      data[:username]
    end
  end
end
