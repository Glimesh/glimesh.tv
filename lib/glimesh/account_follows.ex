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
  alias Glimesh.Streams.Channel

  def get_subscribe_topic(:follows), do: "accounts:follows"
  def get_subscribe_topic(:follows, streamer_id), do: "accounts:follows:#{streamer_id}"

  def subscribe_to(topic_atom, streamer_id),
    do: sub_and_return(get_subscribe_topic(topic_atom, streamer_id))

  defp sub_and_return(topic), do: {Phoenix.PubSub.subscribe(Glimesh.PubSub, topic), topic}

  defp broadcast(%Follower{} = following, :followers = event) do
    Glimesh.Events.broadcast(
      get_subscribe_topic(:follows, following.streamer_id),
      get_subscribe_topic(:follows),
      event,
      following
    )
  end

  def follow(%User{} = streamer, %User{} = user, live_notifications \\ false) do
    attrs = %{
      has_live_notifications: live_notifications
    }

    {action, follower} =
      case get_following(streamer, user, [:streamer, :user]) do
        nil -> {:insert, %Follower{streamer: streamer, user: user}}
        follower -> {:update, follower}
      end

    case follower |> Follower.changeset(attrs) |> Repo.insert_or_update() do
      {:ok, follower} ->
        broadcast(follower, :followers)

        if action == :insert do
          send_follow_message(streamer, user)
        end

        {:ok, follower}

      error ->
        error
    end
  end

  def unfollow(%User{} = streamer, %User{} = user) do
    if follower = Repo.replica().get_by(Follower, streamer_id: streamer.id, user_id: user.id) do
      Repo.delete(follower)
    else
      {:error, "Not following"}
    end
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

  def get_following(%User{} = streamer, %User{} = user, preloads \\ []) do
    Follower
    |> preload(^preloads)
    |> Repo.replica().get_by(streamer_id: streamer.id, user_id: user.id)
  end

  def count_followers(%User{} = user) do
    Repo.one!(from f in Follower, select: count(f.id), where: f.streamer_id == ^user.id)
  end

  def count_following(%User{} = user) do
    Repo.one!(from f in Follower, select: count(f.id), where: f.user_id == ^user.id)
  end

  def list_all_follows, do: Repo.replica().all(query_all_follows())

  def list_followers(%User{} = user),
    do: Repo.replica().all(query_followers(user)) |> Repo.preload(:user)

  def list_following(%User{} = user),
    do: Repo.replica().all(query_following(user)) |> Repo.preload(:streamer)

  def query_all_follows do
    from(f in Follower)
  end

  def query_followers(user) do
    from(f in Follower, where: f.streamer_id == ^user.id)
  end

  def query_following(user) do
    from(f in Follower, where: f.user_id == ^user.id, preload: [:streamer])
  end

  def search_following(user, query, current_page, per_page) do
    like = "%#{query}%"

    Repo.replica().all(
      from u in User,
        inner_join: f in Follower,
        on: f.user_id == ^user.id,
        where: u.id == f.streamer_id,
        where: ilike(u.username, ^like),
        where: u.is_banned == false,
        order_by: [asc: u.id],
        offset: ^((current_page - 1) * per_page),
        limit: ^per_page
    )
  end

  def list_following_with_scroll(streamer, _query, current_page, per_page) do
    Repo.replica().all(
      from f in Follower,
        inner_join: u in User,
        on: u.id == f.streamer_id,
        where: u.is_banned == false,
        where: f.user_id == ^streamer.id,
        offset: ^((current_page - 1) * per_page),
        limit: ^per_page,
        preload: [:streamer]
    )
  end

  def list_follower_with_scroll(streamer, _query, current_page, per_page) do
    Repo.replica().all(
      from f in Follower,
        inner_join: u in User,
        on: u.id == f.user_id,
        where: u.is_banned == false,
        where: f.streamer_id == ^streamer.id,
        offset: ^((current_page - 1) * per_page),
        limit: ^per_page,
        preload: [:user]
    )
  end

  defp send_follow_message(%User{} = streamer, %User{} = user) do
    channel = ChannelLookups.get_channel_for_user(streamer)

    if !is_nil(channel) and
         Chat.can_create_chat_message?(channel, user) and
         not_sent_follow_message_recently?(channel, user) do
      Chat.create_chat_message(user, channel, %{
        message: " just followed the stream!",
        is_followed_message: true
      })
    end
  end

  defp not_sent_follow_message_recently?(%Channel{} = channel, %User{} = user) do
    follow_message = Chat.get_follow_chat_message_for_user(channel, user)

    time_since_last_follow_message =
      case follow_message do
        nil -> 99_999
        _ -> NaiveDateTime.diff(NaiveDateTime.utc_now(), follow_message.inserted_at)
      end

    # Checking if the last follow message is older than 6 hours
    if time_since_last_follow_message > 21_600 do
      true
    else
      false
    end
  end
end
