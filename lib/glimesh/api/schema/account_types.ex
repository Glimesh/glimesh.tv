defmodule Glimesh.Api.AccountTypes do
  @moduledoc false
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers

  alias Glimesh.AccountFollows
  alias Glimesh.Api.AccountResolver
  alias Glimesh.Repo

  object :accounts_queries do
    @desc "Get yourself"
    field :myself, :user do
      resolve(&AccountResolver.myself/3)
    end

    @desc "Query individual user"
    field :user, :user do
      arg(:id, :integer)
      arg(:username, :string)
      resolve(&AccountResolver.find_user/2)
    end
  end

  object :accounts_connection_queries do
    @desc "List all users"
    connection field :users, node_type: :user do
      resolve(&AccountResolver.all_users/2)
    end

    @desc "List all follows or followers"
    connection field :followers, node_type: :follower do
      arg(:streamer_id, :integer)
      arg(:user_id, :integer)
      resolve(&AccountResolver.all_followers/2)
    end
  end

  object :account_mutations do
    @desc "Follow a channel"
    field :follow_create, type: :follower do
      arg(:channel_id, non_null(:id))
      arg(:has_live_notifications, :boolean, default_value: false)

      resolve(&AccountResolver.follow_channel/3)
    end

    @desc "Update a channel follow"
    field :follow_update, type: :follower do
      arg(:channel_id, non_null(:id))
      arg(:has_live_notifications, :boolean, default_value: nil)

      resolve(&AccountResolver.update_follow/3)
    end
    @desc "Unfollow a channel"
    field :follow_remove, type: :follower do
      arg(:channel_id, non_null(:id))

      resolve(&AccountResolver.unfollow_channel/3)
    end
  end

  object :account_subscriptions do
    field :followers, :follower do
      arg(:streamer_id, :id)

      config(fn args, _ ->
        case Map.get(args, :streamer_id) do
          nil ->
            {:ok, topic: [Glimesh.AccountFollows.get_subscribe_topic(:follows)]}

          streamer_id ->
            {:ok, topic: [Glimesh.AccountFollows.get_subscribe_topic(:follows, streamer_id)]}
        end
      end)
    end
  end

  @desc "A user of Glimesh, can be a streamer, a viewer or both!"
  object :user do
    field :id, non_null(:id), description: "Unique User identifier"
    field :username, non_null(:string), description: "Lowercase user identifier"

    field :displayname, non_null(:string),
      description: "Exactly the same as the username, but with casing the user prefers"

    field :team_role, :string,
      description: "The primary role the user performs on the Glimesh team"

    field :allow_glimesh_newsletter_emails, non_null(:boolean)
    field :allow_live_subscription_emails, non_null(:boolean)

    field :email, :string,
      resolve: &AccountResolver.resolve_email/3,
      description: "Email for the user, hidden behind a scope"

    field :confirmed_at, :naive_datetime,
      description: "Datetime the user confirmed their email address"

    field :avatar_url, :string,
      resolve: &AccountResolver.resolve_avatar_url/3,
      description: "URL to the user's avatar"

    field :social_youtube, :string, description: "Qualified URL for the user's YouTube account"

    field :social_instagram, :string,
      description: "Qualified URL for the user's Instagram account"

    field :social_discord, :string, description: "Qualified URL for the user's Discord server"

    field :social_guilded, :string, description: "Qualified URL for the user's Guilded server"

    field :youtube_intro_url, :string, description: "YouTube Intro URL for the user's profile"
    field :profile_content_md, :string, description: "Markdown version of the user's profile"

    field :profile_content_html, :string,
      description: "HTML version of the user's profile, should be safe for rendering directly"

    field :count_followers, :integer do
      resolve(fn user, _, _ ->
        {:ok, AccountFollows.count_followers(user)}
      end)
    end

    field :count_following, :integer do
      resolve(fn user, _, _ ->
        {:ok, AccountFollows.count_following(user)}
      end)
    end

    connection field :followers, node_type: :follower do
      resolve(&AccountResolver.get_user_followers/2)
    end

    connection field :following, node_type: :follower do
      resolve(&AccountResolver.get_user_following/2)
    end

    connection field :following_live_channels, node_type: :channel do
      description("Shortcut to a user's followed channels")
      resolve(&AccountResolver.get_live_user_following_channels/2)
    end

    field :channel, :channel,
      resolve: dataloader(Repo),
      description: "A user's channel, if they have one"

    field :socials, list_of(:user_social),
      resolve: dataloader(Repo),
      description: "A list of linked social accounts for the user"

    field :inserted_at, non_null(:naive_datetime), description: "Account creation date"
    field :updated_at, non_null(:naive_datetime), description: "Account last updated date"
  end

  connection node_type: :user do
    field :count, :integer do
      resolve(fn
        _, %{source: conn} ->
          {:ok, length(conn.edges)}
      end)
    end

    edge do
      field :node, :user do
        resolve(fn %{node: message}, _args, _info ->
          {:ok, message}
        end)
      end
    end
  end

  @desc "A linked social account for a Glimesh user."
  object :user_social do
    field :id, non_null(:id), description: "Unique social account identifier"

    field :platform, :string, description: "Platform that is linked, eg: twitter"

    field :identifier, :string,
      description: "Platform unique identifier, usually a ID, made into a string"

    field :username, :string, description: "Username for the user on the linked platform"

    field :inserted_at, non_null(:naive_datetime), description: "User socials created date"
    field :updated_at, non_null(:naive_datetime), description: "User socials updated date"
  end

  @desc "A follower is a user who subscribes to notifications for a particular user's channel."
  object :follower do
    field :id, non_null(:id), description: "Unique follower identifier"

    field :has_live_notifications, non_null(:boolean),
      description: "Does this follower have live notifications enabled?"

    field :streamer, non_null(:user),
      resolve: dataloader(Repo),
      description: "The streamer the user is following"

    field :user, non_null(:user),
      resolve: dataloader(Repo),
      description: "The user that is following the streamer"

    field :inserted_at, non_null(:naive_datetime), description: "Following creation date"
    field :updated_at, non_null(:naive_datetime), description: "Following updated date"
  end

  connection node_type: :follower do
    field :count, :integer do
      resolve(fn
        _, %{source: conn} ->
          {:ok, length(conn.edges)}
      end)
    end

    edge do
      field :node, :follower do
        resolve(fn %{node: message}, _args, _info ->
          {:ok, message}
        end)
      end
    end
  end
end
