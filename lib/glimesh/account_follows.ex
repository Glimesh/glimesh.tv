defmodule Glimesh.AccountFollows do
  @moduledoc """
  The Followers context
  """
  import Ecto.Query, warn: false

  alias Glimesh.AccountFollows.Follower
  alias Glimesh.Accounts.User
  alias Glimesh.ChannelLookups
  alias Glimesh.Chat
  alias Glimesh.Repo

  def get_subscribe_topic(:follows), do: "accounts:follows"
  def get_subscribe_topic(:follows, streamer_id), do: "accounts:follows:#{streamer_id}"

  def subscribe_to(topic_atom, streamer_id),
    do: sub_and_return(get_subscribe_topic(topic_atom, streamer_id))

  defp sub_and_return(topic), do: {Phoenix.PubSub.subscribe(Glimesh.PubSub, topic), topic}

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, %Follower{} = following}, :followers = event) do
    Glimesh.Events.broadcast(
      get_subscribe_topic(:follows, following.streamer_id),
      get_subscribe_topic(:follows),
      event,
      following
    )

    {:ok, following}
  end

  def follow(%User{} = streamer, %User{} = user, live_notifications \\ false) do
    attrs = %{
      has_live_notifications: live_notifications
    }

    results =
      %Follower{
        streamer: streamer,
        user: user
      }
      |> Follower.changeset(attrs)
      |> Repo.insert()

    channel = ChannelLookups.get_channel_for_user(streamer)

    broadcast(results, :followers)

    if !is_nil(channel) and Glimesh.Chat.can_create_chat_message?(channel, user) and
         no_follow_message_recently(channel, user) do
      Chat.create_chat_message(user, channel, %{
        message: " just followed the stream!",
        is_followed_message: true
      })
    end

    results
  end

  def unfollow(%User{} = streamer, %User{} = user) do
    Repo.get_by(Follower, streamer_id: streamer.id, user_id: user.id) |> Repo.delete()
  end

  def update_following(%Follower{} = following, attrs \\ %{}) do
    following
    |> Repo.preload([:user, :streamer])
    |> Follower.changeset(attrs)
    |> Repo.update()
  end

  def is_following?(%User{} = streamer, %User{} = user) do
    Repo.exists?(
      from f in Follower, where: f.streamer_id == ^streamer.id and f.user_id == ^user.id
    )
  end

  def get_following(%User{} = streamer, %User{} = user) do
    Repo.one(from f in Follower, where: f.streamer_id == ^streamer.id and f.user_id == ^user.id)
  end

  def count_followers(%User{} = user) do
    Repo.one!(from f in Follower, select: count(f.id), where: f.streamer_id == ^user.id)
  end

  def count_following(%User{} = user) do
    Repo.one!(from f in Follower, select: count(f.id), where: f.user_id == ^user.id)
  end

  def list_all_follows do
    Repo.all(from(f in Follower))
  end

  def list_followers(user) do
    Repo.all(from f in Follower, where: f.streamer_id == ^user.id) |> Repo.preload(:user)
  end

  def list_following(user) do
    Repo.all(from f in Follower, where: f.user_id == ^user.id)
  end

  defp no_follow_message_recently(channel, user) do
    follow_message = List.first(Chat.get_follow_chat_message_for_user(channel, user))

    time_since_last_follow_message =
      case follow_message do
        nil -> 99999
        _ -> NaiveDateTime.diff(NaiveDateTime.utc_now(), follow_message.inserted_at)
      end

    # Checking if the last follow message is older than 6 hours
    if time_since_last_follow_message > 21600 do
      true
    else
      false
    end
  end
end
