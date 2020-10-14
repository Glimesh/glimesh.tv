defmodule Glimesh.Streams do
  @moduledoc """
  The Streams context. Contains Channels, Streams, Followers
  """

  import Ecto.Query, warn: false
  alias Glimesh.Accounts.User
  alias Glimesh.Chat
  alias Glimesh.Repo
  alias Glimesh.Streams.Category
  alias Glimesh.Streams.Channel
  alias Glimesh.Streams.ChannelModerationLog
  alias Glimesh.Streams.ChannelModerator
  alias Glimesh.Streams.Followers

  ## Broadcasting Functions

  def get_subscribe_topic(:channel), do: "streams:channel"
  def get_subscribe_topic(:chat), do: "streams:chat"
  def get_subscribe_topic(:chatters), do: "streams:chatters"
  def get_subscribe_topic(:viewers), do: "streams:viewers"
  def get_subscribe_topic(:channel, channel_id), do: "streams:channel:#{channel_id}"
  def get_subscribe_topic(:chat, channel_id), do: "streams:chat:#{channel_id}"
  def get_subscribe_topic(:chatters, channel_id), do: "streams:chatters:#{channel_id}"
  def get_subscribe_topic(:viewers, channel_id), do: "streams:viewers:#{channel_id}"

  def subscribe_to(topic_atom, channel_id),
    do: sub_and_return(get_subscribe_topic(topic_atom, channel_id))

  defp sub_and_return(topic), do: {Phoenix.PubSub.subscribe(Glimesh.PubSub, topic), topic}

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, %Channel{} = channel}, :channel = event) do
    Glimesh.Events.broadcast(
      get_subscribe_topic(:channel, channel.id),
      get_subscribe_topic(:channel),
      event,
      channel
    )

    {:ok, channel}
  end

  defp broadcast_timeout({:error, _reason} = error, _event), do: error

  defp broadcast_timeout({:ok, channel_id, bad_user}, :user_timedout) do
    Glimesh.Events.broadcast(
      get_subscribe_topic(:chat, channel_id),
      get_subscribe_topic(:chat),
      :user_timedout,
      bad_user
    )

    {:ok, bad_user}
  end

  ## Database getters

  def list_channels do
    Repo.all(
      from c in Channel,
        join: cat in Category,
        on: cat.id == c.category_id
    )
    |> Repo.preload([:category, :user])
  end

  def list_live_channels do
    Repo.all(
      from c in Channel,
        where: c.status == "live"
    )
    |> Repo.preload([:category, :user, :stream])
  end

  def list_in_category(category) do
    Repo.all(
      from c in Channel,
        join: cat in Category,
        on: cat.id == c.category_id,
        where: c.status == "live",
        where: cat.id == ^category.id or cat.parent_id == ^category.id
    )
    |> Repo.preload([:category, :user, :stream])
  end

  def list_all_follows do
    Repo.all(from(f in Followers))
  end

  def list_followers(user) do
    Repo.all(from f in Followers, where: f.streamer_id == ^user.id) |> Repo.preload(:user)
  end

  def list_following(user) do
    Repo.all(from f in Followers, where: f.user_id == ^user.id)
  end

  def list_followed_channels(user) do
    Repo.all(
      from c in Channel,
        join: f in Followers,
        on: c.user_id == f.streamer_id,
        where: c.status == "live",
        where: f.user_id == ^user.id
    )
    |> Repo.preload([:category, :user, :stream])
  end

  def get_channel!(id) do
    Repo.get_by!(Channel, id: id) |> Repo.preload([:category, :user])
  end

  def get_channel_for_username!(username, ignore_banned \\ false) do
    Repo.one(
      from c in Channel,
        join: u in User,
        on: c.user_id == u.id,
        where: u.username == ^username,
        where: c.inaccessible == false,
        where: u.is_banned == ^ignore_banned
    )
    |> Repo.preload([:category, :user])
  end

  def get_channel_for_stream_key!(stream_key) do
    Repo.one(
      from c in Channel,
        where: c.stream_key == ^stream_key and c.inaccessible == false
    )
    |> Repo.preload([:category, :user])
  end

  def get_channel_for_user!(user) do
    Repo.one(
      from c in Channel,
        join: u in User,
        on: c.user_id == u.id,
        where: u.id == ^user.id,
        where: c.inaccessible == false
    )
    |> Repo.preload([:category, :user])
  end

  def create_channel(user, attrs \\ %{category_id: Enum.at(list_categories(), 0).id}) do
    %Channel{
      user: user
    }
    |> Channel.create_changeset(attrs)
    |> Repo.insert()
  end

  def delete_channel(%Channel{} = channel) do
    attrs = %{inaccessible: true}

    channel
    |> Channel.changeset(attrs)
    |> Repo.update()
  end

  def update_channel(%Channel{} = channel, attrs) do
    new_channel =
      channel
      |> Channel.changeset(attrs)
      |> Repo.update()

    case new_channel do
      {:error, _changeset} ->
        new_channel

      {:ok, changeset} ->
        broadcast_message = Repo.preload(changeset, :category, force: true)
        broadcast({:ok, broadcast_message}, :channel)
    end
  end

  def change_channel(%Channel{} = channel, attrs \\ %{}) do
    Channel.changeset(channel, attrs)
  end

  def can_change_channel?(_, nil) do
    false
  end

  def can_change_channel?(%Channel{} = channel, user) do
    user.is_admin || channel.user.id == user.id
  end

  ## Moderation

  def add_moderator(%Channel{} = channel, %User{} = moderator) do
    %ChannelModerator{
      channel: channel,
      user: moderator
    }
    |> ChannelModerator.changeset(%{
      :can_short_timeout => true,
      :can_long_timeout => true,
      :can_un_timeout => true,
      :can_ban => true,
      :can_unban => true
    })
    |> Repo.insert()
  end

  def timeout_user(%Channel{} = channel, %User{} = moderator, user_to_timeout) do
    if Chat.can_moderate?(channel, moderator) === false do
      raise "User does not have permission to moderate."
    end

    log =
      %ChannelModerationLog{
        channel: channel,
        moderator: moderator,
        user: user_to_timeout
      }
      |> ChannelModerationLog.changeset(%{action: "timeout"})
      |> Repo.insert()

    :ets.insert(:banned_list, {user_to_timeout.username, true})

    Chat.delete_chat_messages_for_user(channel, user_to_timeout)

    broadcast_timeout({:ok, channel.id, user_to_timeout}, :user_timedout)

    log
  end

  def ban_user(streamer, moderator, user_to_ban) do
    timeout_user(streamer, moderator, user_to_ban)
  end

  ## Following

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

    channel = get_channel_for_user!(streamer)

    if !is_nil(channel) and Glimesh.Chat.can_create_chat_message?(channel, user) do
      Glimesh.Chat.create_chat_message(channel, user, %{
        message: "just followed the stream!"
      })
    end

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

  def get_following(streamer, user) do
    Repo.one!(from f in Followers, where: f.streamer_id == ^streamer.id and f.user_id == ^user.id)
  end

  def count_followers(user) do
    Repo.one!(from f in Followers, select: count(f.id), where: f.streamer_id == ^user.id)
  end

  def count_following(user) do
    Repo.one!(from f in Followers, select: count(f.id), where: f.user_id == ^user.id)
  end

  ## Categories

  alias Glimesh.Streams.Category

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category) |> Repo.preload(:parent)
  end

  def list_categories_for_select do
    Repo.all(from c in Category, order_by: [asc: :tag_name])
    |> Enum.map(&{&1.tag_name, &1.id})
  end

  def list_parent_categories do
    Repo.all(from c in Category, where: is_nil(c.parent_id))
  end

  @spec list_categories_by_parent(atom | %{id: any}) :: any
  def list_categories_by_parent(category) do
    Repo.all(from c in Category, where: c.parent_id == ^category.id)
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(slug),
    do: Repo.one(from c in Category, where: c.slug == ^slug and is_nil(c.parent_id))

  def get_category_by_id!(id), do: Repo.get_by!(Category, id: id)

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  # Streams

  def get_stream!(id) do
    Repo.get_by!(Glimesh.Streams.Stream, id: id)
  end

  @doc """
  Starts a stream for a specific channel
  Only called very intentionally by Janus after stream authentication
  Also sends notifications
  """
  def start_stream(%Channel{} = channel) do
    # 0. End all current streams
    stop_active_streams(channel)

    # 1. Create Stream
    {:ok, stream} =
      create_stream(channel, %{
        title: channel.title,
        category_id: channel.category_id,
        started_at: DateTime.utc_now() |> DateTime.to_naive()
      })

    # 2. Change Channel to use Stream
    # 3. Change Channel to Live
    channel
    |> Channel.start_changeset(%{
      stream_id: stream.id
    })
    |> Repo.update()

    # 4. Send Notifications
    # Todo

    {:ok, stream}
  end

  @doc """
  Ends a stream for a specific channel
  Called either intentionally by Janus when the stream ends, or manually by the platform on a timer
  Archives the stream
  """
  def end_stream(%Channel{} = channel) do
    channel = Repo.preload(channel, [:stream])

    {:ok, stream} =
      update_stream(channel.stream, %{
        ended_at: DateTime.utc_now() |> DateTime.to_naive()
      })

    channel
    |> Channel.stop_changeset(%{})
    |> Repo.update()

    {:ok, stream}
  end

  def end_stream(%Glimesh.Streams.Stream{} = stream) do
    {:ok, stream} =
      update_stream(stream, %{
        ended_at: DateTime.utc_now() |> DateTime.to_naive()
      })

    get_channel!(stream.channel_id)
    |> Channel.stop_changeset(%{})
    |> Repo.update()

    {:ok, stream}
  end

  def stop_active_streams(%Channel{} = channel) do
    from(
      s in Glimesh.Streams.Stream,
      where: s.channel_id == ^channel.id and is_nil(s.ended_at)
    )
    |> Glimesh.Repo.update_all(set: [ended_at: DateTime.utc_now() |> DateTime.to_naive()])
  end

  def create_stream(%Channel{} = channel, attrs \\ %{}) do
    %Glimesh.Streams.Stream{
      channel: channel
    }
    |> Glimesh.Streams.Stream.changeset(attrs)
    |> Repo.insert()
  end

  def update_stream(%Glimesh.Streams.Stream{} = stream, attrs) do
    stream
    |> Glimesh.Streams.Stream.changeset(attrs)
    |> Repo.update()
  end

  alias Glimesh.Streams.StreamMetadata

  def get_last_stream_metadata(%Glimesh.Streams.Stream{} = stream) do
    Repo.one(
      from sm in StreamMetadata,
        where: sm.stream_id == ^stream.id,
        limit: 1,
        order_by: [desc: sm.inserted_at]
    )
  end

  def log_stream_metadata(%Glimesh.Streams.Stream{} = stream, attrs \\ %{}) do
    %StreamMetadata{
      stream: stream
    }
    |> StreamMetadata.changeset(attrs)
    |> Repo.insert()

    {:ok, stream |> Repo.preload([:metadata])}
  end
end
