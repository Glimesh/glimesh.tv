defmodule Glimesh.Streams do
  @moduledoc """
  The Streamers context.
  """

  import Ecto.Query, warn: false
  alias Glimesh.Repo
  alias Glimesh.Accounts.User
  alias Glimesh.Streams.UserModerationLog
  alias Glimesh.Chat

  ## Database getters

  @doc """
  Get all streamers.

  ## Examples

      iex> list_streams()
      []

  """
  def list_streams() do
    Repo.all(from u in User, where: u.can_stream == true)
  end

  def get_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username, can_stream: true)
  end

  def get_by_username!(username) when is_binary(username) do
    Repo.get_by!(User, username: username, can_stream: true)
  end

  def timeout_user(streamer, moderator, user_to_timeout) do
    log = %UserModerationLog{
      streamer: streamer,
      moderator: moderator,
      user: user_to_timeout
    }
    |> UserModerationLog.changeset(%{action: "timeout"})
    |> Repo.insert()

    :ets.insert(:banned_list, {user_to_timeout.username, true})

    Chat.delete_chat_messages_for_user(streamer, user_to_timeout)

    broadcast_chats({:ok, user_to_timeout}, :user_timedout)

    log
  end

  def ban_user(streamer, moderator, user_to_ban) do
    timeout_user(streamer, moderator, user_to_ban)
  end

  defp broadcast_chats({:error, _reason} = error, _event), do: error
  defp broadcast_chats({:ok, chat_message}, event) do
    Phoenix.PubSub.broadcast(Glimesh.PubSub, "chats", {event, chat_message})
    {:ok, chat_message}
  end

end
