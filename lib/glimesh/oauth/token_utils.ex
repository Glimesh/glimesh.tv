defmodule Glimesh.OauthHandler.TokenUtils do
  @moduledoc false

  alias ExOauth2Provider.{
    Applications,
    AccessTokens,
    Config,
    Utils.Error
  }
  alias Glimesh.OauthHandler.OauthError

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

  def load_client_introspec({:ok, %{request: request = %{"client_id" => client_id}} = params}, config) do
    client_secret = Map.get(request, "client_secret", "")

    case Applications.load_application(client_id, client_secret, config) do
      nil    -> OauthError.add_error({:ok, params}, OauthError.invalid_ownership())
      client -> {:ok, Map.merge(params, %{client: client})}
    end
  end
  def load_client_introspec({:ok, params}, _config), do: OauthError.add_error({:ok, params}, OauthError.invalid_ownership())
  def load_client_introspec({:error, params}, _config), do: {:error, params}

  def load_access_token({:error, %{error: _} = params}, _config), do: {:error, params}
  def load_access_token({:ok, %{request: %{"token" => _}} = params}, config) do
    {:ok, params}
    |> get_access_token(config)
    |> preload_token_associations(config)
  end
  def load_access_token({:ok, params}, _config), do: Error.add_error({:ok, params}, Error.invalid_request())

  defp get_access_token({:ok, %{request: %{"token" => token}} = params}, config) do
    token
    |> AccessTokens.get_by_token(config)
    |> case do
      nil          -> Error.add_error({:ok, params}, Error.invalid_request())
      access_token -> {:ok, Map.put(params, :access_token, access_token)}
    end
  end

  defp preload_token_associations({:error, params}, _config), do: {:error, params}
  defp preload_token_associations({:ok, %{access_token: access_token} = params}, config) do
    {:ok, Map.put(params, :access_token, Config.repo(config).preload(access_token, :application))}
  end

  def validate_request({:error, params}), do: {:error, params}
  def validate_request({:ok, params}) do
    {:ok, params}
    |> validate_permissions()
    |> validate_accessible()
  end

  defp validate_permissions({:ok, %{access_token: %{application_id: nil}} = params}), do: {:ok, params}
  defp validate_permissions({:ok, %{access_token: %{application_id: _id}} = params}), do: validate_ownership({:ok, params})

  defp validate_ownership({:ok, %{access_token: %{application_id: application_id}, client: %{id: client_id}} = params}) when application_id == client_id, do: {:ok, params}
  defp validate_ownership({:ok, params}), do: OauthError.add_error({:ok, params}, OauthError.invalid_ownership())

  defp validate_accessible({:error, params}), do: {:error, params}
  defp validate_accessible({:ok, %{access_token: access_token} = params}) do
    case AccessTokens.is_accessible?(access_token) do
      true  -> {:ok, params}
      false -> OauthError.add_error({:ok, params}, OauthError.not_accessable())
    end
  end

  def load_resource_owner({:error, params}, _), do: {:error, params}
  def load_resource_owner({:ok, %{access_token: access_token} = params}, config) do
    {:ok, Map.put(params, :access_token, Config.repo(config).preload(access_token, :resource_owner))}
  end
end
