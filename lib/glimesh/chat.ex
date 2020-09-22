defmodule Glimesh.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false

  alias Glimesh.Streams.UserModerationLog
  alias Glimesh.Chat.ChatMessage
  alias Glimesh.Repo
  alias Glimesh.Streams
  alias Phoenix.HTML
  alias Phoenix.HTML.Link
  alias Phoenix.HTML.Tag

  @doc """
  Returns the list of chat_messages.

  ## Examples

      iex> list_chat_messages()
      [%ChatMessage{}, ...]

  """
  def list_chat_messages(streamer) do
    Repo.all(
      from m in ChatMessage,
        where: m.is_visible == true and m.streamer_id == ^streamer.id,
        order_by: [desc: :inserted_at],
        limit: 50
    )
    |> Repo.preload([:user, :streamer])
    |> Enum.reverse()
  end

  @doc """
  Returns the list of chat_messages.

  ## Examples

      iex> list_chat_messages()
      [%ChatMessage{}, ...]

  """
  def list_chat_user_messages(streamer, user) do
    Repo.all(
      from m in ChatMessage,
        where:
          m.is_visible == true and
            m.streamer_id == ^streamer.id and
            m.user_id == ^user.id,
        order_by: [desc: :inserted_at]
    )
    |> Repo.preload([:user, :streamer])
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
  def get_chat_message!(id), do: Repo.get!(ChatMessage, id) |> Repo.preload([:user, :streamer])

  @doc """
  Creates a chat_message.

  ## Examples

      iex> create_chat_message(%{field: value})
      {:ok, %ChatMessage{}}

      iex> create_chat_message(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_chat_message(streamer, user, attrs \\ %{}) do
    username = user.username

    case :ets.lookup(:banned_list, username) do
      [{^username, {streamid, banned}}] ->
        if streamid === streamer.id and banned do
          raise ArgumentError, message: "user must not be banned"
        else
          true
        end
      [] -> true
    end

    case :ets.lookup(:timedout_list, username) do
      [{^username, {streamid, time}}] ->
        if streamid === streamer.id and DateTime.compare(DateTime.utc_now(), time) !== :gt do
          raise ArgumentError, message: "user must not be timedout"
        else
          true
        end
      [] -> true
    end

    %ChatMessage{
      streamer: streamer,
      user: user
    }
    |> ChatMessage.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:chat_sent)
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
  def delete_chat_messages_for_user(streamer, user) do
    query =
      from m in ChatMessage,
        where:
          m.is_visible == true and
            m.streamer_id == ^streamer.id and
            m.user_id == ^user.id

    Repo.update_all(query, set: [is_visible: false])
  end

  @doc """
  Deletes all chat messages for the streamers chat
  """
  def delete_all_chat_messages(streamer) do
    query =
      from m in ChatMessage,
        where:
          m.is_visible == true and
            m.streamer_id == ^streamer.id

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

  alias Glimesh.Streams.UserModerator
  def can_moderate?(nil, nil), do: false
  def can_moderate?(_streamer, nil), do: false

  def can_moderate?(streamer, user) do
    user.is_admin ||
      Repo.exists?(
        from m in UserModerator, where: m.streamer_id == ^streamer.id and m.user_id == ^user.id
      ) ||
      streamer.id == user.id
  end

  def render_global_badge(user) do
    if user.is_admin do
      Tag.content_tag(:span, "Team Glimesh", class: "badge badge-danger")
    else
      ""
    end
  end

  def render_stream_badge(stream, user) do
    cond do
      stream.id === user.id and user.is_admin === false ->
        Tag.content_tag(:span, "Streamer", class: "badge badge-light")
      can_moderate?(stream, user) and user.is_admin === false ->
        Tag.content_tag(:span, "Moderator", class: "badge badge-info")
      user.id === 0 ->
        Tag.content_tag(:span, "System", class: "badge badge-danger")
      true ->
        ""
    end
  end

  def user_in_message(nil, _msg) do
    false
  end

  def user_in_message(user, chat_message) do
    username = user.username

    !(username == chat_message.user.username ||
      chat_message.user.id == 0) &&
        (String.match?(chat_message.message, ~r/\b#{username}\b/i) ||
          String.match?(chat_message.message, ~r/\b#{"@" <> username}\b/i))
  end

  def hyperlink_message(chat_message) do
    regex_string = ~r/ (?:(?:https?|ftp)
                        :\/\/|\b(?:[a-z\d]+\.))(?:(?:[^\s()<>]+|\((?:[^\s()<>]+|(?:\([^\s()<>]+\)))
                        ?\))+(?:\((?:[^\s()<>]+|(?:\(?:[^\s()<>]+\)))?\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))?
                      /xi

    found_uris = flatten_list(Regex.scan(regex_string, chat_message))

    for message <- String.split(chat_message) do
      if Enum.member?(found_uris, message) do
        case URI.parse(message).scheme do
          "https" -> Link.link(message <> " ", to: message, target: "_blank") |> HTML.safe_to_string()
          "http" -> Link.link(message <> " ", to: message, target: "_blank") |> HTML.safe_to_string()
          _ -> message <> " "
        end
      else
        message <> " "
      end
    end
  end

  def subscribe(user) do
    Phoenix.PubSub.subscribe(Glimesh.PubSub, "chats:#{user.id}")
  end


  def timeout_user(streamer, moderator, user_to_timeout, time) do
    if can_moderate?(streamer, moderator) === false do
      raise "User does not have permission to moderate."
    end

    log =
      %UserModerationLog{
        streamer: streamer,
        moderator: moderator,
        user: user_to_timeout
      }
      |> UserModerationLog.changeset(%{action: "timeout"})
      |> Repo.insert()

    :ets.insert(:timedout_list, {user_to_timeout.username, {streamer.id, time}})

    delete_chat_messages_for_user(streamer, user_to_timeout)

    broadcast({:ok, %{streamer: streamer, user: user_to_timeout, moderator: moderator}}, :user_timedout)

    log
  end

  def ban_user(streamer, moderator, user_to_ban) do
    if can_moderate?(streamer, moderator) === false do
      raise "User does not have permission to moderate."
    end

    log =
      %UserModerationLog{
        streamer: streamer,
        moderator: moderator,
        user: user_to_ban
      }
      |> UserModerationLog.changeset(%{action: "ban"})
      |> Repo.insert()

    :ets.insert(:banned_list, {user_to_ban.username, {streamer.id, true}})

    delete_chat_messages_for_user(streamer, user_to_ban)

    broadcast({:ok, %{streamer: streamer, user: user_to_ban, moderator: moderator}}, :user_banned)

    log
  end

  def unban_user(streamer, moderator, user_to_unban) do
    if can_moderate?(streamer, moderator) === false do
      raise "User does not have permission to moderate."
    end

    log =
      %UserModerationLog{
        streamer: streamer,
        moderator: moderator,
        user: user_to_unban
      }
      |> UserModerationLog.changeset(%{action: "unban"})
      |> Repo.insert()

    :ets.delete(:banned_list, user_to_unban.username)

    broadcast({:ok, %{streamer: streamer, user: user_to_unban, moderator: moderator}}, :user_unbanned)

    log
  end

  def clear_chat(streamer, moderator) do
    if can_moderate?(streamer, moderator) === false do
      raise "User does not have permission to moderate."
    end

    log =
      %UserModerationLog{
        streamer: streamer,
        moderator: moderator,
        user: moderator
      }
      |> UserModerationLog.changeset(%{action: "clear_chat"})
      |> Repo.insert()

    delete_all_chat_messages(streamer)

    broadcast({:ok, %{streamer: streamer, moderator: moderator}}, :chat_cleared)

    log
  end

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, chat_message}, event) do
    streamer_id = chat_message.streamer.id

    Phoenix.PubSub.broadcast(
      Glimesh.PubSub,
      Streams.get_subscribe_topic(:chat, streamer_id),
      {event, chat_message}
    )

    {:ok, chat_message}
  end

  defp flatten_list([head | tail]), do: flatten_list(head) ++ flatten_list(tail)
  defp flatten_list([]), do: []
  defp flatten_list(element), do: [element]
end
