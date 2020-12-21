defmodule Glimesh.Resolvers.ChannelResolver do
  @moduledoc false
  alias Glimesh.Accounts
  alias Glimesh.Payments
  alias Glimesh.Streams

  # Channels

  def all_channels(_, _) do
    {:ok, Streams.list_channels()}
  end

  def find_channel(%{id: id}, _) do
    {:ok, Streams.get_channel!(id)}
  end

  def find_channel(%{username: username}, _) do
    {:ok, Streams.get_channel_for_username!(username)}
  end

  # def find_channel(%{stream_key: stream_key}, %{context: %{user_access: %UserAccess{chat: true, user: user}}}) do
  def find_channel(%{stream_key: stream_key}, %{context: %{is_admin: true}}) do
    {:ok, Streams.get_channel_for_stream_key!(stream_key)}
  end

  def find_channel(%{stream_key: _}, _) do
    {:error, "Unauthorized to access streamKey query."}
  end

  # Streams

  def start_stream(_parent, %{channel_id: channel_id}, %{context: %{is_admin: true}}) do
    channel = Streams.get_channel!(channel_id)
    {:ok, stream} = Streams.start_stream(channel)

    {:ok, stream}
  end

  def start_stream(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end

  def end_stream(_parent, %{stream_id: stream_id}, %{context: %{is_admin: true}}) do
    stream = Streams.get_stream!(stream_id)

    Streams.end_stream(stream)
  end

  def end_stream(_parent, _args, %{context: %{is_admin: true}}) do
    {:error, "Must specify streamId"}
  end

  def end_stream(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end

  def log_stream_metadata(_parent, %{stream_id: stream_id, metadata: metadata}, %{
        context: %{is_admin: true}
      }) do
    stream = Streams.get_stream!(stream_id)
    {:ok, stream} = Streams.log_stream_metadata(stream, metadata)

    {:ok, stream}
  end

  def log_stream_metadata(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end

  def upload_stream_thumbnail(_parent, %{stream_id: stream_id, thumbnail: thumbnail}, %{
        context: %{is_admin: true}
      }) do
    stream = Streams.get_stream!(stream_id)

    Streams.update_stream(stream, %{
      thumbnail: thumbnail
    })
  end

  def upload_stream_thumbnail(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end

  def create_stream(_parent, %{channel_id: channel_id}, %{context: %{is_admin: true}}) do
    channel = Streams.get_channel!(channel_id)
    {:ok, stream} = Streams.create_stream(channel)

    {:ok, stream}
  end

  def create_stream(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end

  def update_stream(_parent, %{id: id} = args, %{context: %{is_admin: true}}) do
    {:ok, stream} = Streams.update_stream(Streams.get_stream!(id), args)

    {:ok, stream}
  end

  def update_stream(_parent, _args, _resolution) do
    {:error, "Access denied"}
  end

  # Categories

  def all_categories(_, _) do
    {:ok, Streams.list_categories()}
  end

  def find_category(%{slug: slug}, _) do
    {:ok, Streams.get_category!(slug)}
  end

  # Subscriptions

  def all_subscriptions(%{streamer_username: streamer_username}, _) do
    streamer = Accounts.get_by_username(streamer_username)

    {:ok, Payments.list_streamer_subscribers(streamer)}
  end

  def all_subscriptions(%{user_username: user_username}, _) do
    user = Accounts.get_by_username(user_username)

    {:ok, Payments.list_user_subscriptions(user)}
  end

  def all_subscriptions(%{streamer_username: streamer_username, user_username: user_username}, _) do
    user = Accounts.get_by_username(user_username)
    streamer = Accounts.get_by_username(streamer_username)

    {:ok, Payments.get_channel_subscription!(user, streamer)}
  end

  def all_subscriptions(_, _) do
    {:ok, Payments.list_all_subscriptions()}
  end

  # Followers

  def all_followers(%{streamer_username: streamer_username}, _) do
    streamer = Accounts.get_by_username(streamer_username)
    {:ok, Streams.list_followers(streamer)}
  end

  def all_followers(%{user_username: user_username}, _) do
    user = Accounts.get_by_username(user_username)
    {:ok, Streams.list_following(user)}
  end

  def all_followers(%{streamer_username: streamer_username, user_username: user_username}, _) do
    streamer = Accounts.get_by_username(streamer_username)
    user = Accounts.get_by_username(user_username)
    {:ok, Streams.get_following(streamer, user)}
  end

  def all_followers(_, _) do
    {:ok, Streams.list_all_follows()}
  end
end
