defmodule Glimesh.OauthHandler do
  @moduledoc """
  Handler for dealing with generating access grants.
  """
  alias ExOauth2Provider.{
    Authorization.Utils,
    Authorization.Utils.Response,
    Config,
    Utils.Error}
  alias Ecto.Schema

  @doc """
  Check ExOauth2Provider.Authorization.Code for usage.
  """
  @spec preauthorize(Schema.t(), map(), keyword()) :: Response.success() | Response.error() | Response.redirect() | Response.native_redirect()
  def preauthorize(resource_owner, request, config \\ []) do
    case validate_response_type(request, config) do
      {:error, :invalid_response_type} -> unsupported_response_type(resource_owner, request, config)
      {:error, :missing_response_type} -> invalid_request(resource_owner, request, config)
      {:ok, token_module}              -> token_module.preauthorize(resource_owner, request, config)
    end
  end

  @doc """
  Check ExOauth2Provider.Authorization.Code for usage.
  """
  @spec authorize(Schema.t(), map(), keyword()) :: {:ok, binary()} | Response.error() | Response.redirect() | Response.native_redirect()
  def authorize(resource_owner, request, config \\ []) do
    case validate_response_type(request, config) do
      {:error, :invalid_response_type} -> unsupported_response_type(resource_owner, request, config)
      {:error, :missing_response_type} -> invalid_request(resource_owner, request, config)
      {:ok, token_module}              -> token_module.authorize(resource_owner, request, config)
    end
  end

  @doc """
  Check ExOauth2Provider.Authorization.Code for usage.
  """
  @spec deny(Schema.t(), map(), keyword()) :: Response.error() | Response.redirect()
  def deny(resource_owner, request, config \\ []) do
    case validate_response_type(request, config) do
      {:error, :invalid_response_type} -> unsupported_response_type(resource_owner, request, config)
      {:error, :missing_response_type} -> invalid_request(resource_owner, request, config)
      {:ok, token_module}              -> token_module.deny(resource_owner, request, config)
    end
  end

  defp unsupported_response_type(resource_owner, request, config),
    do: handle_error_response(resource_owner, request, Error.unsupported_response_type(), config)

  defp invalid_request(resource_owner, request, config),
    do: handle_error_response(resource_owner, request, Error.invalid_request(), config)

  defp handle_error_response(resource_owner, request, error, config) do
    resource_owner
    |> Utils.prehandle_request(request, config)
    |> Error.add_error(error)
    |> Response.error_response(config)
  end

  defp validate_response_type(%{"response_type" => type}, config) do
    type
    |> response_type_to_grant_flow()
    |> fetch_module(config)
    |> case do
      nil -> {:error, :invalid_response_type}
      mod -> {:ok, mod}
    end
  end
  defp validate_response_type(_, _config), do: {:error, :missing_response_type}

  defp response_type_to_grant_flow("code"), do: "authorization_code"
  defp response_type_to_grant_flow("token"), do: "implicit_grant"
  defp response_type_to_grant_flow(_), do: nil

  defp fetch_module(grant_flow, config) do
    config
    |> Config.grant_flows()
    |> flow_can_be_used?(grant_flow)
    |> case do
      true  -> flow_to_mod(grant_flow)
      false -> nil
    end
  end

  defp flow_can_be_used?(grant_flows, grant_flow) do
    Enum.member?(grant_flows, grant_flow)
  end

  defp flow_to_mod("authorization_code"), do: ExOauth2Provider.Authorization.Code
  defp flow_to_mod("implicit_grant"), do: Glimesh.Authorization.Token
  defp flow_to_mod(_), do: nil
end
