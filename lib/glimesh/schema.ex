defmodule Glimesh.Schema do
  @moduledoc """
  GraphQL Schema for the API
  """

  use Absinthe.Schema

  alias Glimesh.Repo

  import_types(Absinthe.Type.Custom)

  import_types(Glimesh.Schema.AccountTypes)
  import_types(Glimesh.Schema.ChannelTypes)

  query do
    import_fields(:accounts_queries)
    import_fields(:streams_queries)
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
