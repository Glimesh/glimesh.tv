defmodule Glimesh.Chat do
  @moduledoc """
  The Chat context.
  """

  import Ecto.Query, warn: false
  alias Glimesh.Repo

  alias Glimesh.Chat.ChatMessage

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
      [{^username, _}] -> raise ArgumentError, message: "user must not be banned"
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
  def delete_chat_messages_for_user(streamer, user) do
    query = from m in ChatMessage,
                 where:
                   m.is_visible == true and
                   m.streamer_id == ^streamer.id and
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

  def empty_chat_message() do
    ChatMessage.changeset(%ChatMessage{}, %{})
  end

  alias Glimesh.Streams.UserModerator
  def can_moderate?(nil, nil), do: false
  def can_moderate?(_streamer, nil), do: false
  def can_moderate?(streamer, user) do
    user.is_admin || Repo.exists?(from m in UserModerator, where: m.streamer_id == ^streamer.id and m.user_id == ^user.id)
  end

  def render_global_badge(user) do
    if user.is_admin do
      Phoenix.HTML.Tag.content_tag(:span, "Team Glimesh", class: "badge badge-danger")
    else
      ""
    end
  end

  def render_stream_badge(stream, user) do
    if can_moderate?(stream, user) and user.is_admin === false do
      Phoenix.HTML.Tag.content_tag(:span, "Moderator", class: "badge badge-info")
    else
      ""
    end
  end

  def user_in_message(username, chat_message) do
    !(username==chat_message.user.username) && ( String.match?(chat_message.message, ~r/#{username}/i) || String.match?(chat_message.message, ~r/#{"@"<>username}/i))
  end

  def subscribe do
    Phoenix.PubSub.subscribe(Glimesh.PubSub, "chats")
  end

  defp broadcast({:error, _reason} = error, _event), do: error
  defp broadcast({:ok, chat_message}, event) do
    Phoenix.PubSub.broadcast(Glimesh.PubSub, "chats", {event, chat_message})
    {:ok, chat_message}
  end
end
