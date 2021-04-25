defmodule Glimesh.Api.GraphiQLPlug do
  @moduledoc false
  defdelegate init(opts), to: Absinthe.Plug.GraphiQL
  defdelegate call(conn, opts), to: Absinthe.Plug.GraphiQL
  defdelegate pipeline(config, opts), to: Absinthe.Plug.GraphiQL
end
