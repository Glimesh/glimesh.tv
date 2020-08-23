defmodule Glimesh.Schema do
  @moduledoc """
  GraphQL Schema for the API
  """

  use Absinthe.Schema

  alias Glimesh.Repo
  alias Glimesh.Streams

  import_types(Glimesh.Schema.DataTypes)

  query do
    @desc "Get a list of channels"
    field :channels, list_of(:channel) do
      resolve(fn _parent, _args, _resolution ->
        {:ok, Streams.list_channels()}
      end)
    end

    @desc "Get a list of users"
    field :users, list_of(:user) do
      resolve(fn _parent, _args, _resolution ->
        {:ok, Glimesh.Accounts.list_users()}
      end)
    end

    @desc "Get a list of chat messages"
    field :chat_messages, list_of(:chat_message) do
      resolve(fn _parent, _args, _resolution ->
        streamer = Streams.get_channel_for_username!("clone1018")

        {:ok, Glimesh.Chat.list_chat_messages(streamer)}
      end)
    end
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Repo, Dataloader.Ecto.new(Repo))

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end
