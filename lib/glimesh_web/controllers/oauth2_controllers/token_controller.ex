defmodule GlimeshWeb.Oauth2Provider.TokenController do
  @moduledoc false
  use GlimeshWeb, :controller

  alias ExOauth2Provider.Token
  alias Glimesh.OauthHandler.TokenUtils

  def create(conn, params) do
    params
    |> Token.grant(otp_app: :glimesh)
    |> case do
      {:ok, access_token} ->
        json(conn, access_token)

      {:error, error, status} ->
        conn
        |> put_status(status)
        |> json(error)
    end
  end

  def revoke(conn, params) do
    params
    |> Token.revoke(otp_app: :glimesh)
    |> case do
      {:ok, response} ->
        json(conn, response)

      {:error, error, status} ->
        conn
        |> put_status(status)
        |> json(error)
    end
  end

  def introspec(conn, params) do
    config = [otp_app: :glimesh]

    return =
      {:ok, %{request: params}}
      |> TokenUtils.load_client_introspec(config)
      |> TokenUtils.load_access_token(config)
      |> TokenUtils.load_resource_owner(config)
      |> TokenUtils.validate_request()

    case return do
      {:error, response} ->
        case response.error_status do
          :not_accessable ->
            json(conn, %{active: false})

          :invalid_ownership ->
            json(conn, %{
              error: "invalid_ownership",
              error_discription:
                "Client ID or Client Secret does not match the tokens application."
            })
        end

      {:ok, response} ->
        user = response.access_token.resource_owner

        json(conn, %{
          active: true,
          username: user.username,
          user_id: user.id,
          scopes: response.access_token.scopes
        })
    end
  end
end
