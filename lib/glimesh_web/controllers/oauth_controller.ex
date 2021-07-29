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

  def token(conn, %{"client_id" => _}) do
    conn
    |> Glimesh.OauthMigration.token_request()
    |> Glimesh.OauthMigration.patch_body_params()
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

  def authorize(
        %Plug.Conn{query_params: query_params} = conn,
        %{"client_id" => _}
      ) do
    # Convert the client_id if we have an old one
    # Store the query params, we'll need them for later
    conn =
      conn
      |> Glimesh.OauthMigration.token_request()
      |> Glimesh.OauthMigration.patch_body_params()

    store_oauth_request(conn, conn.query_params)

    app = Glimesh.Apps.get_app_by_client_id!(conn.query_params["client_id"])
    scopes = Map.get(query_params, "scope", "") |> String.split()

    conn
    |> render("authorize.html", app: app, scopes: scopes, params: query_params)
  end

  def process_authorize(conn, %{"action" => "authorize"}) do
    current_user = conn.assigns[:current_user]

    # Put the query params back in from the original oauth request
    conn =
      Map.update(conn, :query_params, %{}, fn e ->
        Map.merge(e, get_session(conn, :oauth_request) || %{})
      end)

    Oauth.authorize(
      conn,
      %ResourceOwner{
        sub: Integer.to_string(current_user.id),
        username: current_user.username
      },
      __MODULE__
    )
  end

  def process_authorize(conn, %{"action" => "deny"}) do
    authorize_error(conn, %Error{
      status: :unauthorized,
      error: :access_denied,
      format: :query,
      error_description: "The resource owner or authorization server denied the request."
    })
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

  # @impl Boruta.Oauth.Application
  # def authorize_error(
  #       conn,
  #       %Error{status: :unauthorized, error: :invalid_resource_owner}
  #     ) do
  #   # NOTE after siging in the user shall be redirected to `get_session(conn, :user_return_to)`
  #   redirect(conn, to: Routes.user_session_path(:new))
  # end

  @impl Boruta.Oauth.Application
  def authorize_error(
        conn,
        %Error{
          error: error,
          error_description: error_description,
          format: format,
          redirect_uri: redirect_uri
        }
      ) do
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
        |> put_view(OauthView)
        |> render("error.html", error: error, error_description: error_description)
    end
  end

  def introspect(%Plug.Conn{} = conn, _params) do
    conn
    |> Glimesh.OauthMigration.token_request()
    |> Glimesh.OauthMigration.patch_body_params()
    |> Oauth.introspect(__MODULE__)
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
    conn
    |> Glimesh.OauthMigration.token_request()
    |> Glimesh.OauthMigration.patch_body_params()
    |> Oauth.revoke(__MODULE__)
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
    conn
    |> put_status(status)
    |> put_view(OauthView)
    |> render("error.json", error: error, error_description: error_description)
  end

  defp store_oauth_request(conn, params) do
    conn
    |> put_session(
      :oauth_request,
      Map.take(params, [
        "client_id",
        "redirect_uri",
        "response_type",
        "scope",
        "state"
      ])
    )
  end
end
