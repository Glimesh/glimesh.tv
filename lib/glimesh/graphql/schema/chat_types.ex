defmodule Glimesh.Schema.ChatTypes do
  @moduledoc false
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers

  alias Glimesh.Repo
  alias Glimesh.Resolvers.ChatResolver
  alias Glimesh.Streams

  input_object :chat_message_input do
    field :message, :string
  end

  object :chat_mutations do
    @desc "Create a chat message"
    field :create_chat_message, type: :chat_message do
      arg(:channel_id, non_null(:id))
      arg(:message, non_null(:chat_message_input))

      resolve(&ChatResolver.create_chat_message/3)
    end

    @desc "Short timeout (5 minutes) a user from a chat channel."
    field :short_timeout_user, type: :channel_moderation_log do
      arg(:channel_id, non_null(:id))
      arg(:user_id, non_null(:id))

      resolve(&ChatResolver.short_timeout_user/3)
    end

    @desc "Long timeout (15 minutes) a user from a chat channel."
    field :long_timeout_user, type: :channel_moderation_log do
      arg(:channel_id, non_null(:id))
      arg(:user_id, non_null(:id))

      resolve(&ChatResolver.long_timeout_user/3)
    end

    @desc "Ban a user from a chat channel."
    field :ban_user, type: :channel_moderation_log do
      arg(:channel_id, non_null(:id))
      arg(:user_id, non_null(:id))

      resolve(&ChatResolver.ban_user/3)
    end

    @desc "Unban a user from a chat channel."
    field :unban_user, type: :channel_moderation_log do
      arg(:channel_id, non_null(:id))
      arg(:user_id, non_null(:id))

      resolve(&ChatResolver.unban_user/3)
    end
  end

  object :chat_subscriptions do
    field :chat_message, :chat_message do
      arg(:channel_id, :id)

      config(fn args, _ ->
        case Map.get(args, :channel_id) do
          nil -> {:ok, topic: [Streams.get_subscribe_topic(:chat)]}
          channel_id -> {:ok, topic: [Streams.get_subscribe_topic(:chat, channel_id)]}
        end
      end)
    end
  end

  interface :chat_message_token do
    field :type, :string
    field :text, :string

    resolve_type(fn
      %{type: "text"}, _ -> :text_token
      %{type: "url"}, _ -> :url_token
      %{type: "emote"}, _ -> :emote_token
      _, _ -> nil
    end)
  end

  object :text_token do
    field :type, :string
    field :text, :string

    interface(:chat_message_token)
  end

  object :url_token do
    field :type, :string
    field :text, :string
    field :url, :string

    interface(:chat_message_token)
  end

  object :emote_token do
    field :type, :string
    field :text, :string

    field :url, :string do
      # Resolve URL to our actual public route
      resolve(fn token, _, _ ->
        {:ok, GlimeshWeb.Router.Helpers.static_url(GlimeshWeb.Endpoint, token.src)}
      end)
    end

    field :src, :string

    interface(:chat_message_token)
  end

  @desc "A chat message sent to a channel by a user."
  object :chat_message do
    field :id, :id
    field :message, :string, description: "The chat message."

    field :tokens, list_of(:chat_message_token)

    field :channel, non_null(:channel), resolve: dataloader(Repo)
    field :user, non_null(:user), resolve: dataloader(Repo)

    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
  end

  @desc "A channel timeout or ban"
  object :channel_ban do
    field :channel, non_null(:channel), resolve: dataloader(Repo)
    field :user, non_null(:user), resolve: dataloader(Repo)

    field :expires_at, :naive_datetime
    field :reason, :string

    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
  end

  @desc "A channel moderator"
  object :channel_moderator do
    field :channel, non_null(:channel), resolve: dataloader(Repo)
    field :user, non_null(:user), resolve: dataloader(Repo)

    field :can_short_timeout, :boolean
    field :can_long_timeout, :boolean
    field :can_un_timeout, :boolean
    field :can_ban, :boolean
    field :can_unban, :boolean

    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
  end

  @desc "A moderation event that happened"
  object :channel_moderation_log do
    field :channel, non_null(:channel), resolve: dataloader(Repo)
    field :moderator, non_null(:user), resolve: dataloader(Repo)
    field :user, non_null(:user), resolve: dataloader(Repo)

    field :action, :string

    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
  end
end
