defmodule Glimesh.Authorization.TokenUtils do
  @moduledoc false

  alias ExOauth2Provider.{Applications, Utils.Error}

  @doc false
  @spec load_client({:ok, map()}, keyword()) :: {:ok, map()} | {:error, map()}
  def load_client({:ok, %{request: request = %{"client_id" => client_id}} = params}, config) do
    client_secret = Map.get(request, "client_secret", "")

    case Applications.load_application(client_id, client_secret, config) do
      nil    -> Error.add_error({:ok, params}, Error.invalid_client())
      client -> {:ok, Map.merge(params, %{client: client})}
    end
  end
  def load_client({:ok, params}, _config), do: Error.add_error({:ok, params}, Error.invalid_request())
  def load_client({:error, params}, _config), do: {:error, params}

  def prehandle_request(resource_owner, request, config) do
    resource_owner
    |> new_params(request)
    |> load_client(config)
    |> set_defaults()
  end

  defp new_params(resource_owner, request) do
    {:ok, %{resource_owner: resource_owner, request: request}}
  end

  defp set_defaults({:error, params}), do: {:error, params}
  defp set_defaults({:ok, %{request: request, client: client} = params}) do
    [redirect_uri | _rest] = String.split(client.redirect_uri)

    request = Map.new()
    |> Map.put("redirect_uri", redirect_uri)
    |> Map.put("scope", nil)
    |> Map.merge(request)

    {:ok, Map.put(params, :request, request)}
  end

  def remove_empty_values(map) when is_map(map) do
    map
    |> Enum.filter(fn {_, v} -> v != nil && v != "" end)
    |> Enum.into(%{})
  end
end
