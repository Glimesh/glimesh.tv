defmodule Glimesh.Schema do
  use Absinthe.Schema

  alias Glimesh.Repo

  import_types(Glimesh.Schema.DataTypes)

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Repo, Dataloader.Ecto.new(Repo))

    # |> Dataloader.add_source(Streams, Streams.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  query do
    @desc "Get a list of users"
    field :users, list_of(:user) do
      resolve(fn _parent, _args, _resolution ->
        {:ok, Glimesh.Streams.list_streams()}
      end)
    end

    @desc "Get a list of chat messages"
    field :chat_messages, list_of(:chat_message) do
      resolve(fn _parent, _args, _resolution ->
        streamer = Glimesh.Streams.get_by_username!("clone1018")

        {:ok, Glimesh.Chat.list_chat_messages(streamer)}
      end)
    end
  end
end
