defmodule Glimesh.Schema.AccountTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  alias Glimesh.Avatar
  alias Glimesh.Resolvers.AccountsResolver

  object :accounts_queries do
    @desc "Get yourself"
    field :myself, :user do
      resolve(&AccountsResolver.myself/3)
    end

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
      # Need to strip the asset_host url from this property
      resolve(fn user, _, _ ->
        avatar_path =
          case Application.get_env(:waffle, :asset_host) do
            nil ->
              Avatar.url({user.avatar, user})

            asset_host ->
              asset_host = String.trim_trailing(asset_host, "/")
              full_url = Avatar.url({user.avatar, user})
              String.replace(full_url, asset_host, "")
          end

        {:ok, avatar_path}
      end)
    end

    field :avatar_url, :string do
      resolve(fn user, _, _ ->
        avatar_url =
          case Application.get_env(:waffle, :asset_host) do
            nil ->
              GlimeshWeb.Router.Helpers.static_url(
                GlimeshWeb.Endpoint,
                Avatar.url({user.avatar, user})
              )

            _ ->
              Avatar.url({user.avatar, user})
          end

        {:ok, avatar_url}
      end)
    end

    field :social_twitter, :string, description: "Qualified URL for the user's Twitter account"
    field :social_youtube, :string, description: "Qualified URL for the user's YouTube account"

    field :social_instagram, :string,
      description: "Qualified URL for the user's Instagram account"

    field :social_discord, :string, description: "Qualified URL for the user's Discord server"

    field :youtube_intro_url, :string, description: "YouTube Intro URL for the user's profile"
    field :profile_content_md, :string, description: "Markdown version of the user's profile"

    field :profile_content_html, :string,
      description: "HTML version of the user's profile, should be safe for rendering directly"
  end
end
