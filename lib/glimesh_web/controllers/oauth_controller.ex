defmodule GlimeshWeb.OauthController do
  @behaviour Boruta.Oauth.Application

  use GlimeshWeb, :controller

  alias Boruta.Oauth

  alias Boruta.Oauth.{
    AuthorizeResponse,
    Error,
    IntrospectResponse,
    ResourceOwner,
    TokenResponse
  }

  alias GlimeshWeb.OauthView

  def token(%{body_params: %{"client_id" => _}} = conn, _params) do
    conn |> Oauth.token(__MODULE__)
  end

  def token(conn, _params) do
    conn
    |> token_error(%Error{
      error: :invalid_client,
      error_description: "Missing client_id.",
      status: :bad_request
    })
  end

  @impl Boruta.Oauth.Application
  def token_success(conn, %TokenResponse{} = response) do
    conn
    |> put_view(OauthView)
    |> render("token.json", response: response)
  end

  @impl Boruta.Oauth.Application
  def token_error(conn, %Error{status: status, error: error, error_description: error_description}) do
    if error == :invalid_request do
      case GlimeshWeb.Oauth2Provider.TokenController.create(conn.body_params) do
        {:ok, token} ->
          json(conn, token)

        _ ->
          token_error(conn, status, error, error_description)
      end
    else
      token_error(conn, status, error, error_description)
    end
  end

  defp token_error(conn, status, error, error_description) do
    conn
    |> put_status(status)
    |> put_view(OauthView)
    |> render("error.json", error: error, error_description: error_description)
  end

  def authorize(%Plug.Conn{query_params: query_params} = conn, _params) do
    current_user = conn.assigns[:current_user]

    conn = store_user_return_to(conn, query_params)

    Oauth.authorize(
      conn,
      %ResourceOwner{sub: Integer.to_string(current_user.id), username: current_user.username},
      __MODULE__
    )
  end

  @impl Boruta.Oauth.Application
  def authorize_success(
        conn,
        %AuthorizeResponse{
          type: type,
          redirect_uri: redirect_uri,
          value: value,
          expires_in: expires_in,
          state: state
        }
      ) do
    query_string =
      case state do
        nil ->
          URI.encode_query(%{type => value, "expires_in" => expires_in})

        state ->
          URI.encode_query(%{type => value, "expires_in" => expires_in, "state" => state})
      end

    url =
      case type do
        "access_token" -> "#{redirect_uri}##{query_string}"
        "code" -> "#{redirect_uri}?#{query_string}"
      end

    redirect(conn, external: url)
  end

  @impl Boruta.Oauth.Application
  def authorize_error(
        conn,
        %Error{status: :unauthorized, error: :invalid_resource_owner}
      ) do
    # NOTE after siging in the user shall be redirected to `get_session(conn, :user_return_to)`
    redirect(conn, to: Routes.user_session_path(conn, :new))
  end

  def authorize_error(
        conn,
        %Error{
          status: status,
          error: error,
          error_description: error_description,
          format: format,
          redirect_uri: redirect_uri
        }
      ) do
    if error == :invalid_request do
      case Glimesh.OauthHandler.authorize(
             conn.assigns.current_user,
             conn.query_params,
             otp_app: :glimesh
           ) do
        {:redirect, redirect_uri} ->
          redirect(conn, external: redirect_uri)

        {:native_redirect, payload} ->
          json(conn, payload)

        _ ->
          authorize_error(conn, status, error, error_description, format, redirect_uri)
      end
    else
      authorize_error(conn, status, error, error_description, format, redirect_uri)
    end
  end

  defp authorize_error(conn, status, error, error_description, format, redirect_uri) do
    query_string = URI.encode_query(%{error: error, error_description: error_description})

    case format do
      :query ->
        url = "#{redirect_uri}?#{query_string}"
        redirect(conn, external: url)

      :fragment ->
        url = "#{redirect_uri}##{query_string}"
        redirect(conn, external: url)

      _ ->
        conn
        |> put_status(status)
        |> put_view(OauthView)
        |> render("error.html", error: error, error_description: error_description)
    end
  end

  def introspect(%Plug.Conn{} = conn, _params) do
    conn |> Oauth.introspect(__MODULE__)
  end

  @impl Boruta.Oauth.Application
  def introspect_success(conn, %IntrospectResponse{} = response) do
    conn
    |> put_view(OauthView)
    |> render("introspect.json", response: response)
  end

  @impl Boruta.Oauth.Application
  def introspect_error(conn, %Error{
        status: status,
        error: error,
        error_description: error_description
      }) do
    conn
    |> put_status(status)
    |> put_view(OauthView)
    |> render("error.json", error: error, error_description: error_description)
  end

  def revoke(%Plug.Conn{} = conn, _params) do
    conn |> Oauth.revoke(__MODULE__)
  end

  @impl Boruta.Oauth.Application
  def revoke_success(%Plug.Conn{} = conn) do
    send_resp(conn, 200, "")
  end

  @impl Boruta.Oauth.Application
  def revoke_error(conn, %Error{
        status: status,
        error: error,
        error_description: error_description
      }) do
    if error == :invalid_request do
      case GlimeshWeb.Oauth2Provider.TokenController.revoke(conn.body_params) do
        {:ok, response} ->
          json(conn, response)

        _ ->
          revoke_error(conn, status, error, error_description)
      end
    else
      revoke_error(conn, status, error, error_description)
    end
  end

  defp revoke_error(conn, status, error, error_description) do
    conn
    |> put_status(status)
    |> put_view(OauthView)
    |> render("error.json", error: error, error_description: error_description)
  end

  defp store_user_return_to(conn, params) do
    conn
    |> put_session(
      :user_return_to,
      Routes.oauth_path(conn, :authorize,
        client_id: params["client_id"],
        redirect_uri: params["redirect_uri"],
        response_type: params["response_type"],
        scope: params["scope"],
        state: params["state"]
      )
    )
  end
end
