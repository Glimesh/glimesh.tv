defmodule Glimesh.Streams do
  @moduledoc """
  The Streamers context.
  """

  import Ecto.Query, warn: false
  alias Glimesh.Accounts.User
  alias Glimesh.Chat
  alias Glimesh.Repo
  alias Glimesh.Streams.UserModerationLog
  alias Glimesh.Streams.UserModerator

  ## Database getters

  @doc """
  Get all streamers.

  ## Examples

      iex> list_streams()
      []

  """
  def list_streams do
    Repo.all(from u in User, where: u.can_stream == true)
  end

  def get_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username, can_stream: true)
  end

  def get_by_username!(username) when is_binary(username) do
    Repo.get_by!(User, username: username, can_stream: true)
  end

  def add_moderator(streamer, moderator) do
    %UserModerator{
      streamer: streamer,
      user: moderator
    }
    |> UserModerator.changeset(%{
      :can_short_timeout => true,
      :can_long_timeout => true,
      :can_un_timeout => true,
      :can_ban => true,
      :can_unban => true
    })
    |> Repo.insert()
  end

  def timeout_user(streamer, moderator, user_to_timeout) do
    if Glimesh.Chat.can_moderate?(streamer, moderator) === false do
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

  alias Glimesh.Streams.Followers

  def list_followed_streams(user) do
    Repo.all(
      from f in Followers,
        where: f.user_id == ^user.id,
        join: streamer in assoc(f, :streamer),
        select: streamer
    )
  end

  def follow(streamer, user, live_notifications \\ false) do
    attrs = %{
      has_live_notifications: live_notifications
    }

    results =
      %Followers{
        streamer: streamer,
        user: user
      }
      |> Followers.changeset(attrs)
      |> Repo.insert()

    Glimesh.Chat.create_chat_message(streamer, user, %{message: "just followed the stream!"})

    results
  end

  def unfollow(streamer, user) do
    Repo.get_by(Followers, streamer_id: streamer.id, user_id: user.id) |> Repo.delete()
  end

  def is_following?(streamer, user) do
    Repo.exists?(
      from f in Followers, where: f.streamer_id == ^streamer.id and f.user_id == ^user.id
    )
  end

  def count_followers(user) do
    Repo.one!(from f in Followers, select: count(f.id), where: f.streamer_id == ^user.id)
  end

  def count_following(user) do
    Repo.one!(from f in Followers, select: count(f.id), where: f.user_id == ^user.id)
  end
end
