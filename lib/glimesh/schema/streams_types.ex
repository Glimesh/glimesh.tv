defmodule Glimesh.Schema.StreamsTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers

  alias Glimesh.Repo
  alias Glimesh.Resolvers.StreamsResolver

  object :streams_queries do
    @desc "List all channels"
    field :channels, list_of(:channel) do
      resolve(&StreamsResolver.all_channels/2)
    end

    @desc "Query individual channel"
    field :channel, :channel do
      arg(:username, :string)
      resolve(&StreamsResolver.find_channel/2)
    end

    @desc "List all categories"
    field :categories, list_of(:category) do
      resolve(&StreamsResolver.all_categories/2)
    end

    @desc "Query individual category"
    field :category, :category do
      arg(:slug, :string)
      resolve(&StreamsResolver.find_category/2)
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
    field :tag_name, :string, description: "Parent Name and Name of the category in one string"
    field :slug, :string, description: "Slug of the category"

    field :parent, :category,
      resolve: dataloader(Repo),
      description: "Parent category, if null this is a parent category"
  end

  @desc "A channel is a user's actual container for live streaming."
  object :channel do
    field :id, :id

    field :status, :channel_status
    field :title, :string, description: "The title of the current stream, live or offline."
    field :category, :category, resolve: dataloader(Repo)
    field :language, :string, description: "The language a user can expect in the stream."
    field :thumbnail, :string
    field :stream_key, :string
    field :inaccessible, :boolean, default: false

    field :chat_rules_md, :string
    field :chat_rules_html, :string

    field :stream, :stream, resolve: dataloader(Repo)
    field :user, non_null(:user), resolve: dataloader(Repo)
  end

  @desc "A stream is a single live stream in, either current or historical."
  object :stream do
    field :channel, non_null(:channel), resolve: dataloader(Repo)

    field :title, :string, description: "The title of the stream."
    field :category, non_null(:category), resolve: dataloader(Repo)

    field :started_at, non_null(:datetime)
    field :ended_at, :datetime

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
  end
end
