defmodule Glimesh.Schema.ChannelTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers
  import_types(Absinthe.Plug.Types)

  alias Glimesh.Repo
  alias Glimesh.Resolvers.ChannelResolver
  alias Glimesh.Streams

  input_object :stream_metadata_input do
    field :ingest_server, :string
    field :ingest_viewers, :integer
    field :stream_time_seconds, :integer

    field :source_bitrate, :integer
    field :source_ping, :integer

    field :recv_packets, :integer
    field :lost_packets, :integer
    field :nack_packets, :integer

    field :vendor_name, :string
    field :vendor_version, :string

    field :video_codec, :string
    field :video_height, :integer
    field :video_width, :integer
    field :audio_codec, :string
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

  enum :channel_status do
    value(:live, as: "live")
    value(:offline, as: "offline")
  end

  @desc "Categories are the containers for live streaming content."
  object :category do
    field :id, :id
    field :name, :string, description: "Name of the category"

    field :tags, list_of(:tag), resolve: dataloader(Repo)
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
    field :id, :id
    field :name, :string, description: "Name of the subcategory"
    field :slug, :string, description: "URL friendly name of the subcategory"

    field :user_created, :boolean
    field :source, :string
    field :source_id, :string

    field :background_image_url, :string do
      # Resolve URL to our actual public route
      resolve(fn subcategory, _, _ ->
        {:ok, subcategory.background_image}
      end)
    end

    field :category, :category, resolve: dataloader(Repo)

    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
  end

  @desc "Tags are user created labels that are either global or category specific."
  object :tag do
    field :id, :id
    field :name, :string, description: "Name of the tag"
    field :slug, :string, description: "URL friendly name of the tag"
    field :count_usage, :integer, description: "The number of streams started with this tag"

    field :category, :category, resolve: dataloader(Repo)

    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
  end

  @desc "A channel is a user's actual container for live streaming."
  object :channel do
    field :id, :id

    field :status, :channel_status
    field :title, :string, description: "The title of the current stream, live or offline."
    field :category, :category, resolve: dataloader(Repo)
    field :subcategory, :subcategory, resolve: dataloader(Repo)

    field :mature_content, :boolean,
      description:
        "If the streamer has flagged this channel as only appropriate for Mature Audiences."

    field :language, :string, description: "The language a user can expect in the stream."
    field :thumbnail, :string

    field :stream_key, :string do
      resolve(fn channel, _, %{context: %{current_user: current_user}} ->
        if current_user.is_admin do
          {:ok, Glimesh.Streams.get_stream_key(channel)}
        else
          {:error, "Unauthorized to access streamKey field."}
        end
      end)
    end

    field :hmac_key, :string do
      resolve(fn channel, _, %{context: %{current_user: current_user}} ->
        if current_user.is_admin do
          {:ok, channel.hmac_key}
        else
          {:error, "Unauthorized to access hmacKey field."}
        end
      end)
    end

    field :inaccessible, :boolean

    field :chat_rules_md, :string
    field :chat_rules_html, :string

    field :disable_hyperlinks, :boolean
    field :block_links, :boolean
    field :require_confirmed_email, :boolean
    field :minimum_account_age, :integer

    field :stream, :stream, resolve: dataloader(Repo)

    field :streamer, non_null(:user), resolve: dataloader(Repo)
    field :chat_messages, list_of(:chat_message), resolve: dataloader(Repo)
    field :bans, list_of(:channel_ban), resolve: dataloader(Repo)
    field :moderators, list_of(:channel_moderator), resolve: dataloader(Repo)
    field :moderation_logs, list_of(:channel_moderation_log), resolve: dataloader(Repo)

    field :user, non_null(:user),
      resolve: dataloader(Repo),
      deprecate: "Please use the streamer field"

    field :tags, list_of(:tag), resolve: dataloader(Repo)

    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
  end

  @desc "A stream is a single live stream in, either current or historical."
  object :stream do
    field :id, :id

    field :channel, non_null(:channel), resolve: dataloader(Repo)

    field :title, :string, description: "The title of the stream."
    field :category, non_null(:category), resolve: dataloader(Repo)
    field :subcategory, :subcategory, resolve: dataloader(Repo)
    field :metadata, list_of(:stream_metadata), resolve: dataloader(Repo)

    field :started_at, non_null(:naive_datetime)
    field :ended_at, :naive_datetime

    # field :viewers, :viewers, resolve: dataloader(Repo)
    # field :chatters, :chatters, resolve: dataloader(Repo)

    field :count_viewers, :integer
    field :count_chatters, :integer

    field :peak_viewers, :integer
    field :peak_chatters, :integer
    field :avg_viewers, :integer
    field :avg_chatters, :integer
    field :new_subscribers, :integer
    field :resub_subscribers, :integer

    field :thumbnail, :string do
      resolve(fn stream, _, _ ->
        {:ok, Glimesh.StreamThumbnail.url({stream.thumbnail, stream})}
      end)
    end

    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
  end

  @desc "A single instance of stream metadata."
  object :stream_metadata do
    field :id, :id

    field :stream, non_null(:stream), resolve: dataloader(Repo)

    field :ingest_server, :string
    field :ingest_viewers, :string
    field :stream_time_seconds, :integer

    field :source_bitrate, :integer
    field :source_ping, :integer

    field :recv_packets, :integer
    field :lost_packets, :integer
    field :nack_packets, :integer

    field :vendor_name, :string
    field :vendor_version, :string

    field :video_codec, :string
    field :video_height, :integer
    field :video_width, :integer
    field :audio_codec, :string

    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
  end

  @desc "A subscription is an exchange of money for support."
  object :sub do
    field :id, :id
    field :is_active, :boolean
    field :started_at, non_null(:datetime)
    field :ended_at, :datetime
    field :price, :integer
    field :product_name, :string

    field :streamer, :user, resolve: dataloader(Repo)
    field :user, non_null(:user), resolve: dataloader(Repo)

    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
  end
end
