defmodule Glimesh.Api.ChannelResolver do
  @moduledoc false
  import Ecto.Query

  alias Glimesh.Api
  alias Glimesh.ChannelCategories
  alias Glimesh.ChannelLookups
  alias Glimesh.Chat.ChatMessage
  alias Glimesh.Streams

  @error_not_found "Could not find resource"
  @error_access_denied "Access denied"

  # Channel Resolvers
  def resolve_stream_key(channel, _, %{context: %{current_user: current_user}}) do
    if current_user.is_admin do
      {:ok, Glimesh.Streams.get_stream_key(channel)}
    else
      {:error, "Unauthorized to access streamKey field."}
    end
  end

  def resolve_hmac_key(channel, _, %{context: %{current_user: current_user}}) do
    if current_user.is_admin do
      {:ok, channel.hmac_key}
    else
      {:error, "Unauthorized to access hmacKey field."}
    end
  end

  # Channels

  def all_channels(args, _) do
    case query_all_channels(args) do
      {:ok, channels} ->
        Api.connection_from_query_with_count(channels, args)

      {:error, message} ->
        {:error, message}
    end
  end

  defp query_all_channels(%{status: status, category_slug: category_slug}) do
    if category = ChannelCategories.get_category(category_slug) do
      channels =
        ChannelLookups.query_channels(status: status, category_id: category.id)
        |> order_by(:id)

      {:ok, channels}
    else
      {:error, "Category not found"}
    end
  end

  defp query_all_channels(%{status: status}) do
    {:ok, ChannelLookups.query_channels(status: status) |> order_by(:id)}
  end

  defp query_all_channels(_) do
    {:ok, ChannelLookups.query_channels() |> order_by(:id)}
  end

  def find_channel(%{id: id}, _) do
    if channel = ChannelLookups.get_channel(id) do
      {:ok, channel}
    else
      {:error, @error_not_found}
    end
  end

  def find_channel(%{streamer_username: username}, _) do
    if channel = ChannelLookups.get_channel_for_username(username) do
      {:ok, channel}
    else
      {:error, @error_not_found}
    end
  end

  def find_channel(%{streamer_id: user_id}, _) do
    if channel = ChannelLookups.get_channel_for_user_id(user_id) do
      {:ok, channel}
    else
      {:error, @error_not_found}
    end
  end

  def find_channel(_, _), do: {:error, @error_not_found}

  # Streams
  def start_stream(_parent, %{channel_id: channel_id}, %{context: %{is_admin: true}}) do
    with %Glimesh.Streams.Channel{} = channel <- ChannelLookups.get_channel(channel_id),
         {:ok, channel} <- Streams.start_stream(channel) do
      {:ok, channel}
    else
      nil ->
        {:error, @error_not_found}

      {:error, _} ->
        {:error, @error_access_denied}
    end
  end

  def start_stream(_parent, _args, _resolution) do
    {:error, @error_access_denied}
  end

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
    {:error, @error_not_found}
  end

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

  # Connection Resolvers
  def get_messages(args, %{source: channel}) do
    ChatMessage
    |> where(channel_id: ^channel.id)
    |> order_by(:id)
    |> Api.connection_from_query_with_count(args)
  end

  # Moderations

  def get_tags(args, %{source: category}) do
    Streams.Tag
    |> where(category_id: ^category.id)
    |> order_by(:id)
    |> Api.connection_from_query_with_count(args)
  end

  def get_subcategories(args, %{source: category}) do
    Streams.Subcategory
    |> where(category_id: ^category.id)
    |> order_by(:id)
    |> Api.connection_from_query_with_count(args)
  end

  def get_bans(args, %{source: channel}) do
    Streams.ChannelBan
    |> where(channel_id: ^channel.id)
    |> order_by(:id)
    |> Api.connection_from_query_with_count(args)
  end

  def get_moderators(args, %{source: channel}) do
    Streams.ChannelModerator
    |> where(channel_id: ^channel.id)
    |> order_by(:id)
    |> Api.connection_from_query_with_count(args)
  end

  def get_moderation_logs(args, %{source: channel}) do
    Streams.ChannelModerationLog
    |> where(channel_id: ^channel.id)
    |> order_by(:id)
    |> Api.connection_from_query_with_count(args)
  end

  def get_streams(args, %{source: channel}) do
    Streams.Stream
    |> where(channel_id: ^channel.id)
    |> order_by(:id)
    |> Api.connection_from_query_with_count(args)
  end

  def get_stream_metadata(args, %{source: stream}) do
    Streams.StreamMetadata
    |> where(stream_id: ^stream.id)
    |> order_by(:id)
    |> Api.connection_from_query_with_count(args)
  end
end
