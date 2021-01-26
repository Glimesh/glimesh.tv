defmodule Glimesh.Resolvers.ChannelResolver do
  @moduledoc false
  alias Glimesh.Accounts
  alias Glimesh.Payments
  alias Glimesh.Streams
  alias Glimesh.ChannelLookups
  alias Glimesh.ChannelCategories

  # Channels

  def all_channels(_, _) do
    {:ok, ChannelLookups.list_channels()}
  end

  def find_channel(%{id: id}, _) do
    {:ok, ChannelLookups.get_channel!(id)}
  end

  def find_channel(%{username: username}, _) do
    {:ok, ChannelLookups.get_channel_for_username!(username)}
  end

  # def find_channel(%{stream_key: stream_key}, %{context: %{user_access: %UserAccess{chat: true, user: user}}}) do
  def find_channel(%{stream_key: stream_key}, %{context: %{is_admin: true}}) do
    {:ok, ChannelLookups.get_channel_for_stream_key!(stream_key)}
  end

  def find_channel(%{stream_key: _}, _) do
    {:error, "Unauthorized to access streamKey query."}
  end

  # Streams

  def start_stream(_parent, %{channel_id: channel_id}, %{context: %{is_admin: true}}) do
    channel = ChannelLookups.get_channel!(channel_id)

    case Streams.start_stream(channel) do
      {:error, _} -> {:error, "User is unauthorized to start a stream."}
      other -> other
    end
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

    Streams.log_stream_metadata(stream, metadata)
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

  # Categories

  def all_categories(_, _) do
    {:ok, ChannelCategories.list_categories()}
  end

  def find_category(%{slug: slug}, _) do
    {:ok, ChannelCategories.get_category(slug)}
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
