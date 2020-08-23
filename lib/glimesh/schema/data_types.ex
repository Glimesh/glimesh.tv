defmodule Glimesh.Schema.DataTypes do
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers

  alias Glimesh.Repo

   object :stream do
     field :stream_title, :string, name: "title", description: "The title of the stream"
     field :category, non_null(:category), resolve: dataloader(Repo)

     field :streamer, non_null(:user), name: "user", resolve: dataloader(Repo)
   end

   object :category do
     field :id, :id
     field :name, :string, description: "Name of the category"
     field :tag_name, :string, description: "Parent Name and Name of the category in one string"
     field :slug, :string, description: "Slug of the category"

     field :parent, :category, resolve: dataloader(Repo)
  end

  object :user do
    field :id, :id

    field :username, :string
    field :displayname, :string
    field :email, :string
    # field :confirmed_at, :naive_datetime

    # field :avatar, Glimesh.Avatar.Type
    field :social_twitter, :string
    field :social_youtube, :string
    field :social_instagram, :string
    field :social_discord, :string

    field :youtube_intro_url, :string
    field :profile_content_md, :string
    field :profile_content_html, :string
  end

  object :chat_message do
    field :id, :id
    field :message, :string

    field :user, non_null(:user), resolve: dataloader(Repo)
    field :streamer, non_null(:user), resolve: dataloader(Repo)
  end
end
