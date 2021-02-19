defmodule Glimesh.Schema do
  @moduledoc """
  GraphQL Schema for the API
  """

  use Absinthe.Schema

  alias Glimesh.Repo

  import_types(Absinthe.Type.Custom)

  import_types(Glimesh.Schema.AccountTypes)
  import_types(Glimesh.Schema.ChannelTypes)
  import_types(Glimesh.Schema.ChatTypes)

  query do
    import_fields(:accounts_queries)
    import_fields(:streams_queries)
  end

  mutation do
    import_fields(:streams_mutations)
    import_fields(:chat_mutations)
  end

  subscription do
    import_fields(:account_subscriptions)
    import_fields(:streams_subscriptions)
    import_fields(:chat_subscriptions)
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
