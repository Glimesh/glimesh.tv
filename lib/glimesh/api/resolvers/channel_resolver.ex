defmodule Glimesh.Api.ChannelResolver do
  @moduledoc false
  import Ecto.Query

  alias Glimesh.Api
  alias Glimesh.ChannelCategories
  alias Glimesh.ChannelLookups
  alias Glimesh.Chat.ChatMessage
  alias Glimesh.Homepage
  alias Glimesh.Streams
  alias Absinthe.Subscription

  @error_not_found "Could not find resource"
  @error_access_denied "Access denied"
  @edge_not_found "Edge not found"

  # Channel Resolvers
  def resolve_stream_key(channel, _, %{context: %{access: access}}) do
    case Bodyguard.permit(Glimesh.Api.Scopes, :stream_mutations, access) do
      :ok -> {:ok, Glimesh.Streams.get_stream_key(channel)}
      _ -> {:error, "Unauthorized to access streamKey field."}
    end
  end

  def resolve_hmac_key(channel, _, %{context: %{access: access}}) do
    case Bodyguard.permit(Glimesh.Api.Scopes, :stream_mutations, access) do
      :ok ->
        {:ok, channel.hmac_key}

      _ ->
        {:error, "Unauthorized to access hmacKey field."}
    end
  end

  def update_stream_info(_parent, %{channel_id: channel_id, title: title}, %{
        context: %{access: access}
      }) do
    with :ok <- Bodyguard.permit(Glimesh.Api.Scopes, :stream_info, access) do
      channel = Glimesh.ChannelLookups.get_channel(channel_id)

      if channel !== nil do
        case Streams.update_channel(access.user, channel, %{title: title}) do
          {:ok, changeset} ->
            {:ok, changeset}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:error, Api.parse_ecto_changeset_errors(changeset)}

          {:error, :unauthorized} ->
            {:error, :unauthorized}
        end
      else
        {:error, "Channel not found"}
      end
    end
  end

  # Channels

  def watch_channel(_parent, %{channel_id: channel_id, country: country}, %{
        context: %{access: access}
      }) do
    case Glimesh.Janus.get_closest_edge_location(country) do
      %Glimesh.Janus.EdgeRoute{} = edge ->
        Glimesh.Presence.track_presence(
          self(),
          Glimesh.Streams.get_subscribe_topic(:viewers, channel_id),
          access.access_identifier,
          %{
            janus_edge_id: edge.id
          }
        )

        {:ok, edge}

      _ ->
        # In the event we can't find an edge, something is real wrong
        {:error, @edge_not_found}
    end
  end

  def watch_channel(_parent, _args, _resolution) do
    {:error, @edge_not_found}
  end

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

  def list_homepage_channels(args, _) do
    homepage_channel_ids = Homepage.list_homepage_channels()

    Glimesh.Streams.Channel
    |> where([c], c.id in ^homepage_channel_ids)
    |> order_by(:id)
    |> Api.connection_from_query_with_count(args)
  end

  # Streams
  def start_stream(_parent, %{channel_id: channel_id}, %{context: %{access: access}}) do
    with :ok <- Bodyguard.permit(Glimesh.Api.Scopes, :stream_mutations, access) do
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
  end

  def start_stream(_parent, _args, _resolution) do
    {:error, @error_access_denied}
  end

  def end_stream(_parent, %{stream_id: stream_id}, %{context: %{access: access}}) do
    with :ok <- Bodyguard.permit(Glimesh.Api.Scopes, :stream_mutations, access) do
      if stream = Streams.get_stream(stream_id) do
        Streams.end_stream(stream)
      else
        {:error, @error_not_found}
      end
    end
  end

  def end_stream(_parent, _args, _resolution) do
    {:error, @error_access_denied}
  end

  def log_stream_metadata(_parent, %{stream_id: stream_id, metadata: metadata}, %{
        context: %{access: access}
      }) do
    with :ok <- Bodyguard.permit(Glimesh.Api.Scopes, :stream_mutations, access) do
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
  end

  def log_stream_metadata(_parent, _args, _resolution) do
    {:error, @error_not_found}
  end

  def upload_stream_thumbnail(_parent, %{stream_id: stream_id, thumbnail: thumbnail}, %{
        context: %{access: access}
      }) do
    with :ok <- Bodyguard.permit(Glimesh.Api.Scopes, :stream_mutations, access) do
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

  # Sends a message over client id
  def send_interactive_message(_parent, args, %{context: %{access: %{access_type: "app"}}}) do
    event_name = Map.get(args, :event_name)
    session = Map.get(args, :session_id)
    data = Map.get(args, :data)

    Subscription.publish(
      GlimeshWeb.Endpoint,
      %{data: data, event_name: event_name, authorized: false},
      Keyword.put([], :interactive, "streams:interactive:#{session}")
    )

    {:ok, %{data: data, event_name: event_name, authorized: false}}
  end

  # Sends a message with an access token
  def send_interactive_message(_parent, args, %{context: %{access: access}}) do
    # Get the data from the message
    event_name = Map.get(args, :event_name)
    session = Map.get(args, :session_id)
    data = Map.get(args, :data)

    # Check that it has interactive scope, channel matches sessionID
    # If so it is an authorized message, if not it isn't
    with true <- Map.get(access.scopes, :interactive),
         %Glimesh.Streams.Channel{} = channel <-
           ChannelLookups.get_channel_for_username(access.user.username),
         true <- channel.id == session do
      Subscription.publish(
        GlimeshWeb.Endpoint,
        %{data: data, event_name: event_name, authorized: true},
        Keyword.put([], :interactive, "streams:interactive:#{session}")
      )

      {:ok, %{data: data, event_name: event_name, authorized: true}}
    else
      _ ->
      Subscription.publish(
        GlimeshWeb.Endpoint,
        %{data: data, event_name: event_name, authorized: false},
        Keyword.put([], :interactive, "streams:interactive:#{session}")
      )

      {:ok, %{data: data, event_name: event_name, authorized: false}}
    end
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
