defmodule Glimesh.Oauth.Clients do
  @moduledoc false

  @behaviour Boruta.Oauth.Clients

  import Boruta.Config, only: [repo: 0, cache_backend: 0]
  import Boruta.Ecto.OauthMapper, only: [to_oauth_schema: 1]

  alias Boruta.Ecto
  alias Boruta.Ecto.ClientStore

  @impl Boruta.Oauth.Clients
  def get_by(id: id, secret: secret), do: Boruta.Ecto.Clients.get_by(id: id, secret: secret)

  def get_by(id: id, redirect_uri: redirect_uri),
    do: Boruta.Ecto.Clients.get_by(id: id, redirect_uri: redirect_uri)

  def get_by(attrs) do
    case get_by(:from_cache, attrs) do
      {:ok, client} -> {:ok, client}
      _ -> {:ok, get_by(:from_database, attrs)}
    end
  end

  defp get_by(:from_cache, id: id), do: cache_backend().get({Boruta.Oauth.Clients, id})

  defp get_by(:from_database, id: id) do
    with %Ecto.Client{} = client <- repo().get_by(Ecto.Client, id: id),
         {:ok, client} <- to_oauth_schema(client) |> ClientStore.put() do
      client
    end
  end

  def invalidate(client), do: Boruta.Ecto.Clients.invalidate(client)

  @impl Boruta.Oauth.Clients
  def authorized_scopes(client), do: Boruta.Ecto.Clients.authorized_scopes(client)
end
