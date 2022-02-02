defmodule Glimesh.OldSchema.ChannelTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers
  import_types(Absinthe.Plug.Types)

  alias Glimesh.Repo
  alias Glimesh.OldResolvers.ChannelResolver
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
    @desc "List all channels"
    field :channels, list_of(:channel) do
      arg(:status, :channel_status)
      arg(:category_slug, :string)

      resolve(&ChannelResolver.all_channels/2)
    end

    @desc "Query individual channel"
    field :channel, :channel do
      arg(:id, :id)
      arg(:username, :string)
      arg(:hmac_key, :string)
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

    @desc "List all subscribers or subscribees"
    field :subscriptions, list_of(:sub) do
      arg(:streamer_username, :string)
      arg(:user_username, :string)
      resolve(&ChannelResolver.all_subscriptions/2)
    end
  end

  object :streams_mutations do
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
    field :log_stream_metadata, type: :stream_metadata do
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
    field :tags, list_of(:tag), resolve: dataloader(Repo)

    @desc "Subcategories within the category"
    field :subcategories, list_of(:subcategory), resolve: dataloader(Repo)

    field :tag_name, :string do
      deprecate("Tag name is now just name")

      resolve(fn category, _, _ ->
        {:ok, category.name}
      end)
    end

    field :slug, :string, description: "Slug of the category"

    field :parent, :category do
      deprecate("All categories are now parents and the children are tags.")

      resolve(fn _, _, _ ->
        {:ok, nil}
      end)
    end
  end

  @desc "Subcategories are specific games, topics, or genre's that exist under a Category."
  object :subcategory do
    field :id, :id, description: "ID of subcategory"
    field :name, :string, description: "Name of the subcategory"
    field :slug, :string, description: "URL friendly name of the subcategory"

    field :user_created, :boolean, description: "Was the subcategory created by a user?"
    field :source, :string, description: "Subcategory source"
    field :source_id, :string, description: "Subcategory source ID"

    @desc "Subcategory background image URL"
    field :background_image_url, :string do
      # Resolve URL to our actual public route
      resolve(fn subcategory, _, _ ->
        {:ok, subcategory.background_image}
      end)
    end

    field :category, :category, resolve: dataloader(Repo), description: "Parent category"

    field :inserted_at, non_null(:naive_datetime), description: "Subcategory creation date"
    field :updated_at, non_null(:naive_datetime), description: "Subcategory updated date"
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

  @desc "A channel is a user's actual container for live streaming."
  object :channel do
    field :id, :id, description: "Unique channel identifier"

    field :status, :channel_status, description: "The current status of the channnel"
    field :title, :string, description: "The title of the current stream, live or offline."

    field :category, :category,
      resolve: dataloader(Repo),
      description: "Category the current stream is in"

    field :subcategory, :subcategory,
      resolve: dataloader(Repo),
      description: "Subcategory the current stream is in"

    field :mature_content, :boolean,
      description:
        "If the streamer has flagged this channel as only appropriate for Mature Audiences."

    field :language, :string, description: "The language a user can expect in the stream."
    field :thumbnail, :string, description: "Current stream thumbnail"

    @desc "Current streams unique stream key"
    field :stream_key, :string do
      resolve(fn channel, _, %{context: %{access: access}} ->
        case Bodyguard.permit(Glimesh.Api.Scopes, :stream_mutations, access) do
          :ok ->
            {:ok, Glimesh.Streams.get_stream_key(channel)}

          _ ->
            {:error, "Unauthorized to access streamKey field."}
        end
      end)
    end

    @desc "Hash-based Message Authentication Code for the stream"
    field :hmac_key, :string do
      resolve(fn channel, _, %{context: %{access: access}} ->
        case Bodyguard.permit(Glimesh.Api.Scopes, :stream_mutations, access) do
          :ok ->
            {:ok, channel.hmac_key}

          _ ->
            {:error, "Unauthorized to access hmacKey field."}
        end
      end)
    end

    field :inaccessible, :boolean, description: "Is the stream inaccessible?"

    field :chat_rules_md, :string, description: "Chat rules in markdown"
    field :chat_rules_html, :string, description: "Chat rules in html"

    field :show_recent_chat_messages_only, :boolean,
      description: "Only show recent chat messages?"

    field :disable_hyperlinks, :boolean,
      description: "Toggle for links automatically being clickable"

    field :block_links, :boolean, description: "Toggle for blocking anyone from posting links"

    field :require_confirmed_email, :boolean,
      description: "Toggle for requiring confirmed email before chatting"

    field :minimum_account_age, :integer,
      description: "Minimum account age length before chatting"

    field :stream, :stream,
      resolve: dataloader(Repo),
      description: "If the channel is live, this will be the current Stream"

    field :streamer, non_null(:user),
      resolve: dataloader(Repo),
      description: "User associated with the channel"

    field :chat_messages, list_of(:chat_message),
      resolve: dataloader(Repo),
      description: "List of chat messages sent in the channel"

    field :bans, list_of(:channel_ban),
      resolve: dataloader(Repo),
      description: "List of bans in the channel"

    field :moderators, list_of(:channel_moderator),
      resolve: dataloader(Repo),
      description: "List of moderators in the channel"

    field :moderation_logs, list_of(:channel_moderation_log),
      resolve: dataloader(Repo),
      description: "List of moderation events in the channel"

    field :user, non_null(:user),
      resolve: dataloader(Repo),
      deprecate: "Please use the streamer field"

    field :tags, list_of(:tag),
      resolve: dataloader(Repo),
      description: "Tags associated with the channel"

    field :inserted_at, non_null(:naive_datetime), description: "Channel creation date"
    field :updated_at, non_null(:naive_datetime), description: "Channel updated date"
  end

  @desc "A stream is a single live stream in, either current or historical."
  object :stream do
    field :id, :id, description: "Unique stream identifier"

    field :channel, non_null(:channel),
      resolve: dataloader(Repo),
      description: "Channel running with the stream"

    field :title, :string, description: "The title of the stream."

    field :category, non_null(:category),
      resolve: dataloader(Repo),
      description: "The category the current stream is in"

    field :subcategory, :subcategory,
      resolve: dataloader(Repo),
      description: "The subategory the current stream is in"

    field :metadata, list_of(:stream_metadata),
      resolve: dataloader(Repo),
      description: "Current stream metadata"

    field :started_at, non_null(:naive_datetime),
      description: "Datetime of when the stream was started"

    field :ended_at, :naive_datetime,
      description: "Datetime of when the stream ended, or null if still going"

    # field :viewers, :viewers, resolve: dataloader(Repo)
    # field :chatters, :chatters, resolve: dataloader(Repo)

    field :count_viewers, :integer, description: "Concurrent viewers during last snapshot"
    field :count_chatters, :integer, description: "Concurrent chatters during last snapshot"

    field :peak_viewers, :integer, description: "Peak concurrent viewers"
    field :peak_chatters, :integer, description: "Peak concurrent chatters"
    field :avg_viewers, :integer, description: "Average viewers during the stream"
    field :avg_chatters, :integer, description: "Average chatters during the stream"

    field :new_subscribers, :integer,
      description: "Total new subscribers gained during the stream"

    field :resub_subscribers, :integer, description: "Total resubscribers during the stream"

    @desc "Thumbnail URL of the stream"
    field :thumbnail, :string do
      resolve(fn stream, _, _ ->
        {:ok, Glimesh.StreamThumbnail.url({stream.thumbnail, stream})}
      end)
    end

    field :inserted_at, non_null(:naive_datetime), description: "Stream created date"
    field :updated_at, non_null(:naive_datetime), description: "Stream updated date"
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

  @desc "A subscription is an exchange of money for support."
  object :sub do
    field :id, :id, description: "Subscription unique identifier"
    field :is_active, :boolean, description: "Is the subscription currently active?"
    field :started_at, non_null(:datetime), description: "When the subscription started"
    field :ended_at, :datetime, description: "When the subscription ended"
    field :price, :integer, description: "Price of the subscription"
    field :product_name, :string, description: "Subscription product name"

    field :streamer, :user,
      resolve: dataloader(Repo),
      description: "The streamer receiving the support from the subscription"

    field :user, non_null(:user),
      resolve: dataloader(Repo),
      description: "The user giving the support with the subscription"

    field :inserted_at, non_null(:naive_datetime), description: "Subscription created date"
    field :updated_at, non_null(:naive_datetime), description: "Subscription updated date"
  end
end
