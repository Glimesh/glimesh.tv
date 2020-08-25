defmodule Glimesh.Schema.AccountsTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Glimesh.Resolvers.AccountsResolver

  object :accounts_queries do
    @desc "List all users"
    field :users, list_of(:user) do
      resolve(&AccountsResolver.all_users/2)
    end

    @desc "Query individual user"
    field :user, :user do
      arg(:id, :integer)
      arg(:username, :string)
      resolve(&AccountsResolver.find_user/2)
    end
  end

  @desc "A user of Glimesh, can be a streamer, a viewer or both!"
  object :user do
    field :id, :id

    field :username, :string, description: "Lowercase user identifier"

    field :displayname, :string,
      description: "Exactly the same as the username, but with casing the user prefers"

    # field :email, :string, let's hide this for now :)
    field :confirmed_at, :naive_datetime

    field :avatar, :string do
      resolve(fn user, _, _ ->
        {:ok, Glimesh.Avatar.url({user.avatar, user})}
      end)
    end

    field :social_twitter, :string
    field :social_youtube, :string
    field :social_instagram, :string
    field :social_discord, :string

    field :youtube_intro_url, :string
    field :profile_content_md, :string
    field :profile_content_html, :string
  end
end
