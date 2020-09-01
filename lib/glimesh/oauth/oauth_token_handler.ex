defmodule Glimesh.Authorization.Token do
  @moduledoc false
  alias Glimesh.Authorization.TokenUtils
  alias ExOauth2Provider.{
    Config,
    AccessTokens,
    AccessGrants,
    Authorization.Utils,
    Authorization.Utils.Response,
    RedirectURI,
    Scopes,
    Utils.Error}

  def preauthorize(resource_owner, request, config \\ []) do
    resource_owner
    |> TokenUtils.prehandle_request(request, config)
    |> validate_request(config)
    |> check_previous_authorization(config)
    |> reissue_grant(config)
    |> Response.preauthorize_response(config)
  end

  defp check_previous_authorization({:error, params}, _config), do: {:error, params}
  defp check_previous_authorization({:ok, %{resource_owner: resource_owner, client: application, request: %{"scope" => scopes}} = params}, config) do
    case AccessTokens.get_token_for(resource_owner, application, scopes, config) do
      nil   -> {:ok, params}
      token -> {:ok, Map.put(params, :access_token, token)}
    end
  end

  defp reissue_grant({:error, params}, _config), do: {:error, params}
  defp reissue_grant({:ok, %{access_token: _access_token} = params}, config), do: issue_grant({:ok, params}, config)
  defp reissue_grant({:ok, params}, _config), do: {:ok, params}

  def authorize(resource_owner, request, config \\ []) do
    resource_owner
    |> TokenUtils.prehandle_request(request, config)
    |> validate_request(config)
    |> issue_grant(config)
    |> authorize_response(config)
  end

  defp issue_grant({:error, %{error: _error} = params}, _config), do: {:error, params}
  defp issue_grant({:ok, %{resource_owner: resource_owner, client: application, request: request} = params}, config) do
    {_, %{client: client, request: post_request}} =
      {:ok, %{request: request}}
      |> TokenUtils.load_client(config)
      |> validate_redirect_uri(config)

    result =
      {:ok, %{client: client, resource_owner: resource_owner, scopes: post_request["scope"]}}
      |> maybe_create_access_token(config)

    case result do
      {:ok, {:error, error}} -> Error.add_error({:ok, params}, error)
      {:ok, access_token} -> {:ok, Map.put(params, :access_token, access_token)}
      {:error, error} -> Error.add_error({:ok, params}, error)
    end
  end

  def deny(resource_owner, request, config \\ []) do
    resource_owner
    |> TokenUtils.prehandle_request(request, config)
    |> validate_request(config)
    |> Error.add_error(Error.access_denied())
    |> Response.deny_response(config)
  end

  defp validate_request({:error, params}, _config), do: {:error, params}
  defp validate_request({:ok, params}, config) do
    {:ok, params}
    |> validate_resource_owner()
    |> validate_redirect_uri(config)
    |> validate_scopes(config)
  end

  defp validate_resource_owner({:ok, %{resource_owner: resource_owner} = params}) do
    case resource_owner do
      %{__struct__: _} -> {:ok, params}
      _                -> Error.add_error({:ok, params}, Error.invalid_request())
    end
  end

  defp validate_scopes({:error, params}, _config), do: {:error, params}
  defp validate_scopes({:ok, %{request: %{"scope" => scopes}, client: client} = params}, config) do
    scopes        = Scopes.to_list(scopes)
    server_scopes =
      client.scopes
      |> Scopes.to_list()
      |> Scopes.default_to_server_scopes(config)

    case Scopes.all?(server_scopes, scopes) do
      true  -> {:ok, params}
      false -> Error.add_error({:ok, params}, Error.invalid_scopes())
    end
  end

  defp validate_redirect_uri({:error, params}, _config), do: {:error, params}
  defp validate_redirect_uri({:ok, %{request: %{"redirect_uri" => redirect_uri}, client: client} = params}, config) do
    cond do
      RedirectURI.native_redirect_uri?(redirect_uri, config) ->
        {:ok, params}

      RedirectURI.valid_for_authorization?(redirect_uri, client.redirect_uri, config) ->
        {:ok, params}

      true ->
        Error.add_error({:ok, params}, Error.invalid_redirect_uri())
    end
  end
  defp validate_redirect_uri({:ok, params}, _config), do: Error.add_error({:ok, params}, Error.invalid_request())

  defp maybe_create_access_token({:error, _} = error, _token_params, _config), do: error
  defp maybe_create_access_token({:ok, %{resource_owner: resource_owner, client: application, scopes: scopes}}, config) do
    token_params = %{scopes: scopes, application: application, use_refresh_token: false, expires_in: 604800}

    resource_owner
    |> AccessTokens.get_token_for(application, scopes, config)
    |> case do
      nil          -> AccessTokens.create_token(resource_owner, token_params, config)
      access_token -> {:ok, access_token}
    end
  end

  def authorize_response({:ok, params}, config), do: build_response(params, %{access_token: params.access_token.token, token_type: "bearer", expires_in: params.access_token.expires_in, scope: params.access_token.scopes}, config)
  def authorize_response({:error, %{error: error} = params}, config), do: build_response(params, error, config)

  defp build_response(%{request: request} = params, payload, config) do
    payload = add_state(payload, request)

    case can_redirect?(params, config) do
      true -> build_redirect_response(params, payload, config)
      _    -> build_standard_response(params, payload)
    end
  end

  defp add_state(payload, request) do
    case request["state"] do
      nil ->
        payload

      state ->
        %{"state" => state}
        |> Map.merge(payload)
        |> TokenUtils.remove_empty_values()
    end
  end

  defp build_redirect_response(%{request: %{"redirect_uri" => redirect_uri}} = params, payload, config) do
    case RedirectURI.native_redirect_uri?(redirect_uri, config) do
      true -> {:error, Error.invalid_redirect_uri()}
      _    -> {:redirect, uri_with_query(redirect_uri, payload)}
    end
  end

  defp build_standard_response(%{grant: _}, payload) do
    {:ok, payload}
  end
  defp build_standard_response(%{error: error, error_http_status: error_http_status}, _) do
    {:error, error, error_http_status}
  end
  defp build_standard_response(%{error: error}, _) do # For DB errors
    {:error, error, :bad_request}
  end

  defp can_redirect?(%{error: %{error: :invalid_redirect_uri}}, _config), do: false
  defp can_redirect?(%{error: %{error: :invalid_client}}, _config), do: false
  defp can_redirect?(%{error: %{error: _error}, request: %{"redirect_uri" => redirect_uri}}, config), do: !RedirectURI.native_redirect_uri?(redirect_uri, config)
  defp can_redirect?(%{error: _}, _config), do: false
  defp can_redirect?(%{request: %{}}, _config), do: true

  def uri_with_query(uri, query) when is_binary(uri) do
    uri
    |> URI.parse()
    |> uri_with_query(query)
  end
  def uri_with_query(%URI{} = uri, query) do
    query = add_query_params(uri.query || "", query)

    uri
    |> Map.put(:fragment, query)
    |> to_string()
  end

  defp add_query_params(query, attrs) do
    query
    |> URI.decode_query(attrs)
    |> TokenUtils.remove_empty_values()
    |> URI.encode_query()
  end
end
