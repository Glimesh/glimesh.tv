defmodule Glimesh.Api.Schema do
  @moduledoc """
  GraphQL Schema for the API
  """

  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias Glimesh.Repo

  import_types(Absinthe.Type.Custom)

  import_types(Glimesh.Api.AccountTypes)
  import_types(Glimesh.Api.ChannelTypes)
  import_types(Glimesh.Api.ChatTypes)

  query do
    import_fields(:accounts_queries)
    import_fields(:accounts_connection_queries)

    import_fields(:streams_queries)
    import_fields(:streams_connection_queries)

    import_fields(:chat_autocomplete)
  end

  mutation do
    import_fields(:account_mutations)
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
