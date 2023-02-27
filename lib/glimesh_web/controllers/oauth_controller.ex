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

  alias Glimesh.OauthMigration
  alias GlimeshWeb.OauthView

  def token(conn, %{"client_id" => _}) do
    conn
    |> OauthMigration.token_request()
    |> OauthMigration.patch_body_params()
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

  @impl Boruta.Oauth.Application
  def preauthorize_success(
        conn,
        %Boruta.Oauth.AuthorizationSuccess{} = authorization
      ) do
    app = Glimesh.Apps.get_app_by_client_id!(authorization.client.id)
    scopes = authorization.scope |> String.split()

    conn
    |> store_oauth_request(conn.query_params)
    |> render("authorize.html", app: app, scopes: scopes)
  end

  @impl Boruta.Oauth.Application
  def preauthorize_error(conn, %Boruta.Oauth.Error{} = error) do
    authorize_error(conn, error)
  end

  def authorize(conn, %{"client_id" => _}) do
    current_user = conn.assigns[:current_user]

    conn
    |> OauthMigration.token_request()
    |> OauthMigration.patch_body_params()
    |> Oauth.preauthorize(
      %ResourceOwner{
        sub: Integer.to_string(current_user.id),
        username: current_user.username
      },
      __MODULE__
    )
  end

  def authorize(conn, _) do
    authorize_error(conn, %Error{
      status: :unauthorized,
      error: :access_denied,
      format: :page,
      error_description: "Missing client_id from the request."
    })
  end

  def process_authorize(conn, %{"action" => "authorize"}) do
    current_user = conn.assigns[:current_user]

    conn
    |> Map.update(:query_params, %{}, fn e ->
      Map.merge(e, get_session(conn, :oauth_request) || %{})
    end)
    |> Oauth.authorize(
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
          expires_in: expires_in,
          state: state
        } = resp
      ) do
    state = state_value(state)

    url =
      case type do
        :token ->
          query_string =
            %{"access_token" => resp.access_token, "expires_in" => expires_in}
            |> Map.merge(state)
            |> URI.encode_query()

          "#{redirect_uri}##{query_string}"

        :code ->
          query_string =
            %{"code" => resp.code, "expires_in" => expires_in}
            |> Map.merge(state)
            |> URI.encode_query()

          "#{redirect_uri}?#{query_string}"
      end

    redirect(conn, external: url)
  end

  defp state_value(nil), do: %{}
  defp state_value(state), do: %{"state" => state}

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
    |> OauthMigration.token_request()
    |> OauthMigration.patch_body_params()
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
    |> OauthMigration.token_request()
    |> OauthMigration.patch_body_params()
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
        "state",
        "code_challenge",
        "code_challenge_method"
      ])
    )
  end
end
