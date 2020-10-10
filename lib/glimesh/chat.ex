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
        limit: 50
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
    username = user.username

    case :ets.lookup(:banned_list, username) do
      [{^username, _}] -> raise ArgumentError, message: "user must not be banned"
      [] -> true
    end

    if Glimesh.Accounts.is_user_banned_by_username?(username) do
      raise ArgumentError, message: "User must not be banned"
    end

    if allow_link_in_message(channel, attrs) do
      %ChatMessage{
        channel: channel,
        user: user
      }
      |> ChatMessage.changeset(attrs)
      |> Repo.insert()
      |> broadcast(:chat_message)
    else
      throw_error_on_chat(gettext("This channel has links disabled!"), attrs)
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
  def can_moderate?(nil, nil), do: false
  def can_moderate?(_channel, nil), do: false

  def can_moderate?(channel, user) do
    user.is_admin ||
      Repo.exists?(
        from m in ChannelModerator, where: m.channel_id == ^channel.id and m.user_id == ^user.id
      )
  end

  def can_create_chat_message?(%Channel{} = _, %User{} = user) do
    username = user.username

    case :ets.lookup(:banned_list, username) do
      [{^username, _}] -> false
      [] -> true
    end
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
    if can_moderate?(stream, user) and user.is_admin === false do
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
