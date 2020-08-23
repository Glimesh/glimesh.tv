defmodule Glimesh.Schema.DataTypes do
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers

  alias Glimesh.Repo

  # object :stream do
  #   field :title, :string
  #   field :category, :string

  #   field :user, non_null(:user) do
  #     resolve(dataloader(Repo))
  #   end
  # end

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

    field :user, non_null(:user) do
      resolve(dataloader(Repo))
    end
  end
end
