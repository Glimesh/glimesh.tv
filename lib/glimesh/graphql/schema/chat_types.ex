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

  interface :chat_message_part do
    field :type, :string
    field :text, :string

    resolve_type(fn
      %{type: "text"}, _ -> :text_part
      %{type: "url"}, _ -> :url_part
      %{type: "emote"}, _ -> :emote_part
      _, _ -> nil
    end)
  end

  object :text_part do
    field :type, :string
    field :text, :string

    interface(:chat_message_part)
  end

  object :url_part do
    field :type, :string
    field :text, :string
    field :url, :string

    interface(:chat_message_part)
  end

  object :emote_part do
    field :type, :string
    field :text, :string
    field :url, :string
    field :huge, :boolean
    field :animated, :boolean

    interface(:chat_message_part)
  end

  @desc "A chat message sent to a channel by a user."
  object :chat_message do
    field :id, :id
    field :message, :string, description: "The chat message."

    field :parsed, list_of(:chat_message_part) do
      # Need to strip the asset_host url from this property
      resolve(fn message, _, _ ->
        parsed = Glimesh.Chat.Parser.type_parser(message.message)
        IO.inspect(parsed)
        {:ok, parsed}
      end)
    end

    field :channel, non_null(:channel), resolve: dataloader(Repo)
    field :user, non_null(:user), resolve: dataloader(Repo)

    field :inserted_at, non_null(:naive_datetime)
    field :updated_at, non_null(:naive_datetime)
  end
end
