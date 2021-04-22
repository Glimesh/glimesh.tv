defmodule Glimesh.ResolversNext.ChannelResolver do
  @moduledoc false
  use Appsignal.Instrumentation.Decorators
  import Ecto.Query

  alias Absinthe.Relay.Connection
  alias Glimesh.Accounts
  alias Glimesh.Accounts.User
  alias Glimesh.ChannelCategories
  alias Glimesh.ChannelLookups
  alias Glimesh.Chat.ChatMessage
  alias Glimesh.Payments
  alias Glimesh.Payments.Subscription
  alias Glimesh.Repo
  alias Glimesh.Streams

  @error_not_found "Could not find resource"
  @error_access_denied "Access denied"

  # Channels

  def all_channels(%{status: status, category_slug: category_slug}) do
    if category = ChannelCategories.get_category(category_slug) do
      {:ok, ChannelLookups.list_channels(status: status, category_id: category.id)}
    else
      {:error, @error_not_found}
    end
  end

  def all_channels(%{status: status}) do
    {:ok, ChannelLookups.list_channels(status: status)}
  end

  def all_channels(_) do
    {:ok, ChannelLookups.list_channels()}
  end

  def all_channels(args, _) do
    case all_channels(args) do
      {:ok, channels} ->
        Connection.from_query(channels, &Repo.all/1, args)

      _ ->
        {:error, @error_not_found}
    end
  end

  def find_channel(%{id: id}, _) do
    if channel = ChannelLookups.get_channel(id) do
      {:ok, channel}
    else
      {:error, @error_not_found}
    end
  end

  def find_channel(%{username: username}, _) do
    if channel = ChannelLookups.get_channel_for_username(username) do
      {:ok, channel}
    else
      {:error, @error_not_found}
    end
  end

  def find_channel(%{user_id: user_id}, _) do
    if channel = ChannelLookups.get_channel_for_user_id(user_id) do
      {:ok, channel}
    else
      {:error, @error_not_found}
    end
  end

  def find_channel(%{hmac_key: hmac_key}, %{context: %{is_admin: true}}) do
    case ChannelLookups.get_channel_by_hmac_key(hmac_key) do
      %Glimesh.Streams.Channel{} = channel -> {:ok, channel}
      _ -> {:error, "Channel not found with hmacKey."}
    end
  end

  def find_channel(%{hmac_key: _}, _) do
    {:error, "Unauthorized to access hmacKey query."}
  end

  def find_channel(_, _), do: {:error, @error_not_found}

  # Streams
  @decorate transaction_event()
  def start_stream(_parent, %{channel_id: channel_id}, %{context: %{is_admin: true}}) do
    with %Glimesh.Streams.Channel{} = channel <- ChannelLookups.get_channel(channel_id),
         {:ok, channel} <- Streams.start_stream(channel) do
      {:ok, channel}
    else
      nil ->
        {:error, @error_not_found}

      {:error, _} ->
        {:error, "User is unauthorized to start a stream."}
    end
  end

  def start_stream(_parent, _args, _resolution) do
    {:error, @error_access_denied}
  end

  @decorate transaction_event()
  def end_stream(_parent, %{stream_id: stream_id}, %{context: %{is_admin: true}}) do
    if stream = Streams.get_stream(stream_id) do
      Streams.end_stream(stream)
    else
      {:error, @error_not_found}
    end
  end

  def end_stream(_parent, _args, %{context: %{is_admin: true}}) do
    {:error, "Must specify streamId"}
  end

  def end_stream(_parent, _args, _resolution) do
    {:error, @error_access_denied}
  end

  @decorate transaction_event()
  def log_stream_metadata(_parent, %{stream_id: stream_id, metadata: metadata}, %{
        context: %{is_admin: true}
      }) do
    if stream = Streams.get_stream(stream_id) do
      if is_nil(stream.ended_at) do
        Streams.log_stream_metadata(stream, metadata)
      else
        {:error, "Stream has ended"}
      end
    else
      {:error, @error_not_found}
    end
  end

  def log_stream_metadata(_parent, _args, _resolution) do
    {:error, @error_access_denied}
  end

  @decorate transaction_event()
  def upload_stream_thumbnail(_parent, %{stream_id: stream_id, thumbnail: thumbnail}, %{
        context: %{is_admin: true}
      }) do
    with %Streams.Stream{} = stream <- Streams.get_stream(stream_id),
         {:ok, stream} <- Streams.update_stream(stream, %{thumbnail: thumbnail}) do
      {:ok, stream}
    else
      nil ->
        {:error, @error_not_found}

      {:upload_exit, _} ->
        # Whenever a DO Spaces error occurs, it throws back an error absinthe can't natively process
        {:error, "Error uploading thumbnail"}
    end
  end

  def upload_stream_thumbnail(_parent, _args, _resolution) do
    {:error, @error_access_denied}
  end

  # Categories

  def all_categories(_, _) do
    {:ok, ChannelCategories.list_categories()}
  end

  def find_category(%{slug: slug}, _) do
    if category = ChannelCategories.get_category(slug) do
      {:ok, category}
    else
      {:error, @error_not_found}
    end
  end

  # Subscriptions

  def all_subscriptions(%{streamer_username: streamer_username}, _) do
    if streamer = Accounts.get_by_username(streamer_username) do
      {:ok, Payments.list_streamer_subscribers(streamer)}
    else
      {:error, @error_not_found}
    end
  end

  def all_subscriptions(%{user_username: user_username}, _) do
    if user = Accounts.get_by_username(user_username) do
      {:ok, Payments.list_user_subscriptions(user)}
    else
      {:error, @error_not_found}
    end
  end

  def all_subscriptions(%{streamer_username: streamer_username, user_username: user_username}, _) do
    with %User{} = streamer <- Accounts.get_by_username(streamer_username),
         %User{} = user <- Accounts.get_by_username(user_username),
         %Subscription{} = sub <- Payments.get_channel_subscription(user, streamer) do
      {:ok, sub}
    else
      nil ->
        {:error, @error_not_found}

      _ ->
        {:error, "Unexpected error"}
    end
  end

  def all_subscriptions(%{streamer_id: streamer_id}, _) do
    if streamer = Accounts.get_user(streamer_id) do
      {:ok, Payments.list_streamer_subscribers(streamer)}
    else
      {:error, @error_not_found}
    end
  end

  def all_subscriptions(%{user_id: user_id}, _) do
    if user = Accounts.get_user(user_id) do
      {:ok, Payments.list_user_subscriptions(user)}
    else
      {:error, @error_not_found}
    end
  end

  def all_subscriptions(%{streamer_id: streamer_id, user_id: user_id}, _) do
    with %User{} = streamer <- Accounts.get_user(streamer_id),
         %User{} = user <- Accounts.get_user(user_id),
         %Subscription{} = sub <- Payments.get_channel_subscription(user, streamer) do
      {:ok, sub}
    else
      nil ->
        {:error, @error_not_found}

      _ ->
        {:error, "Unexpected error"}
    end
  end

  def all_subscriptions(_, _) do
    {:ok, Payments.list_all_subscriptions()}
  end

  # Chat

  def get_messages(args, %{source: channel}) do
    # Set the chat message load count to be at 100 since it has to be
    # hitting the repo 202 times for the the messages with isMod queried
    args = Map.put(args, :first, min(Map.get(args, :first), 100))

    ChatMessage
    |> where(channel_id: ^channel.id)
    |> order_by(:inserted_at)
    |> Connection.from_query(&Repo.all/1, args)
  end

  # Moderations

  def get_bans(args, %{source: channel}) do
    args = Map.put(args, :first, min(Map.get(args, :first), 1000))

    Streams.ChannelBan
    |> where(channel_id: ^channel.id)
    |> order_by(:inserted_at)
    |> Connection.from_query(&Repo.all/1, args)
  end

  def get_moderators(args, %{source: channel}) do
    args = Map.put(args, :first, min(Map.get(args, :first), 1000))

    Streams.ChannelModerator
    |> where(channel_id: ^channel.id)
    |> order_by(:inserted_at)
    |> Connection.from_query(&Repo.all/1, args)
  end

  def get_moderation_logs(args, %{source: channel}) do
    args = Map.put(args, :first, min(Map.get(args, :first), 1000))

    Streams.ChannelModerationLog
    |> where(channel_id: ^channel.id)
    |> order_by(:inserted_at)
    |> Connection.from_query(&Repo.all/1, args)
  end
end