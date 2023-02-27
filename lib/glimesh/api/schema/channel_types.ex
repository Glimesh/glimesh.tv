defmodule Glimesh.Api.ChannelTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers
  import_types(Absinthe.Plug.Types)

  alias Glimesh.Api
  alias Glimesh.Api.ChannelResolver
  alias Glimesh.Repo
  alias Glimesh.Streams

  input_object :stream_metadata_input do
    field :ingest_server, :string, description: "Ingest Server URL"
    field :ingest_viewers, :integer, description: "Viewers on the ingest"
    field :stream_time_seconds, :integer, description: "Current Stream time in seconds"

    field :source_bitrate, :integer, description: "Bitrate at the source"
    field :source_ping, :integer, description: "Ping to the source"

    field :recv_packets, :integer, description: "Received stream input data packets"
    field :lost_packets, :integer, description: "Lost stream input data packets"
    field :nack_packets, :integer, description: "Negative Acknowledged stream input data packets"

    field :vendor_name, :string, description: "Client vendor name"
    field :vendor_version, :string, description: "Client vendor version"

    field :video_codec, :string, description: "Stream video codec"
    field :video_height, :integer, description: "Stream video height"
    field :video_width, :integer, description: "Stream video width"
    field :audio_codec, :string, description: "Stream audio codec"
  end

  object :streams_queries do
    @desc "Query individual channel"
    field :channel, :channel do
      arg(:id, :id)
      arg(:streamer_id, :integer)
      arg(:streamer_username, :string)
      resolve(&ChannelResolver.find_channel/2)
    end

    @desc "List all categories"
    field :categories, list_of(:category) do
      resolve(&ChannelResolver.all_categories/2)
    end

    @desc "Query individual category"
    field :category, :category do
      arg(:slug, :string)
      resolve(&ChannelResolver.find_category/2)
    end
  end

  object :streams_connection_queries do
    @desc "List all channels"
    connection field :channels, node_type: :channel do
      arg(:status, :channel_status)
      arg(:category_slug, :string)

      resolve(&ChannelResolver.all_channels/2)
    end

    @desc "List the channels currently on the homepage"
    connection field :homepage_channels, node_type: :channel do
      resolve(&ChannelResolver.list_homepage_channels/2)
    end
  end

  object :streams_mutations do
    @desc "Watch a channel"
    field :watch_channel, type: :edge_route do
      arg(:channel_id, non_null(:id))
      arg(:country, non_null(:string))

      resolve(&ChannelResolver.watch_channel/3)
    end

    @desc "Start a stream"
    field :start_stream, type: :stream do
      arg(:channel_id, non_null(:id))

      resolve(&ChannelResolver.start_stream/3)
    end

    @desc "End a stream"
    field :end_stream, type: :stream do
      arg(:stream_id, non_null(:id))

      resolve(&ChannelResolver.end_stream/3)
    end

    @desc "Update a stream's metadata"
    field :log_stream_metadata, type: :stream do
      arg(:stream_id, non_null(:id))
      arg(:metadata, non_null(:stream_metadata_input))

      resolve(&ChannelResolver.log_stream_metadata/3)
    end

    @desc "Update a stream's thumbnail"
    field :upload_stream_thumbnail, type: :stream do
      arg(:stream_id, non_null(:id))
      arg(:thumbnail, non_null(:upload))

      resolve(&ChannelResolver.upload_stream_thumbnail/3)
    end

    @desc "Update a channel's stream info"
    field :update_stream_info, type: :channel do
      arg(:channel_id, non_null(:id))
      arg(:title, non_null(:string))

      resolve(&ChannelResolver.update_stream_info/3)
    end
  end

  object :streams_subscriptions do
    field :channel, :channel do
      arg(:id, :id)

      config(fn args, _ ->
        case Map.get(args, :id) do
          nil -> {:ok, topic: [Streams.get_subscribe_topic(:channel)]}
          channel_id -> {:ok, topic: [Streams.get_subscribe_topic(:channel, channel_id)]}
        end
      end)
    end
  end

  @desc "Current channel status"
  enum :channel_status do
    value(:live, as: "live")
    value(:offline, as: "offline")
  end

  @desc "Categories are the containers for live streaming content."
  object :category do
    field :id, :id, description: "Unique category identifier"
    field :name, :string, description: "Name of the category"

    @desc "Tags associated with the category"
    connection field :tags, node_type: :tag do
      resolve(&ChannelResolver.get_tags/2)
    end

    @desc "Subcategories within the category"
    connection field :subcategories, node_type: :subcategory do
      resolve(&ChannelResolver.get_subcategories/2)
    end

    field :slug, :string, description: "Slug of the category"

    field :inserted_at, non_null(:naive_datetime), description: "Category creation date"
    field :updated_at, non_null(:naive_datetime), description: "Category updated date"
  end

  @desc "Subcategories are specific games, topics, or genre's that exist under a Category."
  object :subcategory do
    field :id, :id, description: "Unique subcategory identifier"
    field :name, :string, description: "Name of the subcategory"
    field :slug, :string, description: "URL friendly name of the subcategory"

    field :user_created, :boolean, description: "Was the subcategory created by a user?"
    field :source, :string, description: "Subcategory source"
    field :source_id, :string, description: "Subcategory source ID"

    @desc "Subcategory background image URL"
    field :background_image_url, :string do
      resolve(fn subcategory, _, _ ->
        {:ok, subcategory.background_image}
      end)
    end

    field :category, :category, resolve: dataloader(Repo), description: "Parent category"

    field :inserted_at, non_null(:naive_datetime), description: "Subcategory creation date"
    field :updated_at, non_null(:naive_datetime), description: "Subcategory updated date"
  end

  connection node_type: :subcategory do
    field :count, :integer do
      resolve(fn
        _, %{source: conn} ->
          {:ok, length(conn.edges)}
      end)
    end

    edge do
      field :node, :subcategory do
        resolve(fn %{node: subcategory}, _args, _info ->
          {:ok, subcategory}
        end)
      end
    end
  end

  @desc "Tags are user created labels that are either global or category specific."
  object :tag do
    field :id, :id, description: "Unique tag identifier"
    field :name, :string, description: "Name of the tag"
    field :slug, :string, description: "URL friendly name of the tag"
    field :count_usage, :integer, description: "The number of streams started with this tag"

    field :category, :category, resolve: dataloader(Repo), description: "Parent category"

    field :inserted_at, non_null(:naive_datetime), description: "Tag creation date"
    field :updated_at, non_null(:naive_datetime), description: "Tag updated date"
  end

  connection node_type: :tag do
    field :count, :integer do
      resolve(fn
        _, %{source: conn} ->
          {:ok, length(conn.edges)}
      end)
    end

    edge do
      field :node, :tag do
        resolve(fn %{node: tag}, _args, _info ->
          {:ok, tag}
        end)
      end
    end
  end

  @desc "A channel is a user's actual container for live streaming."
  object :channel do
    field :id, :id, description: "Unique channel identifier"

    field :title, :string, description: "The title of the current stream, live or offline."
    field :backend, :string, description: "The video backend of a channel."
    field :status, :channel_status, description: "The current status of the channel"

    field :category, :category,
      resolve: dataloader(Repo),
      description: "Category the current stream is in"

    field :subcategory, :subcategory,
      resolve: dataloader(Repo),
      description: "Subcategory the current stream is in"

    field :tags, list_of(:tag),
      resolve: dataloader(Repo),
      description: "Tags associated with the current stream"

    field :mature_content, :boolean,
      description:
        "If the streamer has flagged this channel as only appropriate for Mature Audiences"

    field :language, :string, description: "The language a user can expect in the stream"

    @desc "Current streams unique stream key"
    field :stream_key, :string, resolve: &ChannelResolver.resolve_stream_key/3

    @desc "Hash-based Message Authentication Code for the stream"
    field :hmac_key, :string, resolve: &ChannelResolver.resolve_hmac_key/3

    field :inaccessible, :boolean, description: "Is the stream inaccessible?"

    field :chat_rules_md, :string, description: "Chat rules in markdown"
    field :chat_rules_html, :string, description: "Chat rules in html"

    field :show_on_homepage, :boolean, description: "Toggle for homepage visibility"

    field :show_recent_chat_messages_only, :boolean,
      description: "Only show recent chat messages?"

    field :disable_hyperlinks, :boolean,
      description: "Toggle for links automatically being clickable"

    field :block_links, :boolean, description: "Toggle for blocking anyone from posting links"

    field :require_confirmed_email, :boolean,
      description: "Toggle for requiring confirmed email before chatting"

    field :minimum_account_age, :integer,
      description: "Minimum account age length before chatting"

    @desc "Channel poster URL"
    field :poster_url, :string do
      resolve(fn channel, _, _ ->
        {:ok, Api.resolve_full_url(Glimesh.ChannelPoster.url({channel.poster, channel}))}
      end)
    end

    @desc "Background URL for the Chat Box"
    field :chat_bg_url, :string do
      resolve(fn channel, _, _ ->
        {:ok, Api.resolve_full_url(Glimesh.ChatBackground.url({channel.chat_bg, channel}))}
      end)
    end

    field :stream, :stream,
      resolve: dataloader(Repo),
      description: "If the channel is live, this will be the current Stream"

    connection field :streams, node_type: :stream do
      resolve(&ChannelResolver.get_streams/2)
    end

    field :streamer, non_null(:user),
      resolve: dataloader(Repo),
      description: "User associated with the channel"

    @desc "List of chat messages sent in the channel"
    connection field :chat_messages, node_type: :chat_message do
      resolve(&ChannelResolver.get_messages/2)
    end

    @desc "List of bans in the channel"
    connection field :bans, node_type: :channel_ban do
      resolve(&ChannelResolver.get_bans/2)
    end

    @desc "List of moderators in the channel"
    connection field :moderators, node_type: :channel_moderator do
      resolve(&ChannelResolver.get_moderators/2)
    end

    @desc "List of moderation events in the channel"
    connection field :moderation_logs, node_type: :channel_moderation_log do
      resolve(&ChannelResolver.get_moderation_logs/2)
    end

    field :inserted_at, non_null(:naive_datetime), description: "Channel creation date"
    field :updated_at, non_null(:naive_datetime), description: "Channel updated date"
  end

  connection node_type: :channel do
    field :count, :integer do
      resolve(fn
        _, %{source: conn} ->
          {:ok, length(conn.edges)}
      end)
    end

    edge do
      field :node, :channel do
        resolve(fn %{node: message}, _args, _info ->
          {:ok, message}
        end)
      end
    end
  end

  @desc "A stream is a single live stream in, either current or historical."
  object :stream do
    field :id, :id, description: "Unique stream identifier"

    field :channel, non_null(:channel),
      resolve: dataloader(Repo),
      description: "Channel running with the stream"

    field :title, :string, description: "The title of the channel when the stream was started"

    field :category, non_null(:category),
      resolve: dataloader(Repo),
      description: "The category the current stream is in"

    @desc "Current stream metadata"
    connection field :metadata, node_type: :stream_metadata do
      resolve(&ChannelResolver.get_stream_metadata/2)
    end

    field :started_at, non_null(:naive_datetime),
      description: "Datetime of when the stream was started"

    field :ended_at, :naive_datetime,
      description: "Datetime of when the stream was ended, or null if still going"

    field :count_viewers, :integer, description: "Concurrent viewers during last snapshot"
    field :peak_viewers, :integer, description: "Peak concurrent viewers"

    @desc "Thumbnail URL of the stream"
    field :thumbnail_url, :string do
      resolve(fn stream, _, _ ->
        {:ok, Api.resolve_full_url(Glimesh.StreamThumbnail.url({stream.thumbnail, stream}))}
      end)
    end

    field :inserted_at, non_null(:naive_datetime), description: "Stream created date"
    field :updated_at, non_null(:naive_datetime), description: "Stream updated date"
  end

  connection node_type: :stream do
    field :count, :integer do
      resolve(fn
        _, %{source: conn} ->
          {:ok, length(conn.edges)}
      end)
    end

    edge do
      field :node, :stream do
        resolve(fn %{node: stream}, _args, _info ->
          {:ok, stream}
        end)
      end
    end
  end

  @desc "A single instance of stream metadata."
  object :stream_metadata do
    field :id, :id, description: "Unique stream metadata identifier"

    field :stream, non_null(:stream),
      resolve: dataloader(Repo),
      description: "Current stream metadata references"

    field :ingest_server, :string, description: "Ingest Server URL"
    field :ingest_viewers, :string, description: "Viewers on the ingest"
    field :stream_time_seconds, :integer, description: "Current Stream time in seconds"

    field :source_bitrate, :integer, description: "Bitrate at the source"
    field :source_ping, :integer, description: "Ping to the source"

    field :recv_packets, :integer, description: "Received stream input data packets"
    field :lost_packets, :integer, description: "Lost stream input data packets"
    field :nack_packets, :integer, description: "Negative Acknowledged stream input data packets"

    field :vendor_name, :string, description: "Client vendor name"
    field :vendor_version, :string, description: "Client vendor version"

    field :video_codec, :string, description: "Stream video codec"
    field :video_height, :integer, description: "Stream video height"
    field :video_width, :integer, description: "Stream video width"
    field :audio_codec, :string, description: "Stream audio codec"

    field :inserted_at, non_null(:naive_datetime), description: "Stream metadata created date"
    field :updated_at, non_null(:naive_datetime), description: "Stream metadata updated date"
  end

  connection node_type: :stream_metadata do
    field :count, :integer do
      resolve(fn
        _, %{source: conn} ->
          {:ok, length(conn.edges)}
      end)
    end

    edge do
      field :node, :stream_metadata do
        resolve(fn %{node: metadata}, _args, _info ->
          {:ok, metadata}
        end)
      end
    end
  end

  @desc "An edge to watch a FTL stream."
  object :edge_route do
    field :id, :id, description: "ID of the edge route"

    field :hostname, :string, description: "Edge hostname"
    field :url, :string, description: "Fully qualified edge URL"
    field :priority, :integer, description: "Edge priority"
    field :available, :integer, description: "Availability of edge for viewer traffic"

    field :country_codes, list_of(:string),
      description: "List of recommended country codes, used for latency"

    field :inserted_at, non_null(:naive_datetime), description: "Edge created date"
    field :updated_at, non_null(:naive_datetime), description: "Edge updated date"
  end
end
