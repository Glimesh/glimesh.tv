defmodule GlimeshWeb.OauthController do
  @behaviour Boruta.Oauth.Application

  use GlimeshWeb, :controller

  alias Boruta.Oauth
  alias Boruta.Oauth.Error
  alias Boruta.Oauth.TokenResponse
  alias GlimeshWeb.OauthView

  def token(%Plug.Conn{} = conn, _params) do
    # Detect if we're using old keys or Boruta keys
    conn
    |> Glimesh.OauthMigration.token_request()
    |> Oauth.token(__MODULE__)
  end

  @impl Boruta.Oauth.Application
  def token_success(conn, %TokenResponse{} = response) do
    conn
    |> put_view(OauthView)
    |> render("token.json", response: response)
  end

  @impl Boruta.Oauth.Application
  def token_error(conn, %Error{status: status, error: error, error_description: error_description}) do
    conn
    |> put_status(status)
    |> put_view(OauthView)
    |> render("error.json", error: error, error_description: error_description)
  end
end
