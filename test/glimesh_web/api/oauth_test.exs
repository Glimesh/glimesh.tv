defmodule GlimeshWeb.Api.OauthTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  import Glimesh.ApiFixtures

  describe "authorize oauth2" do
    setup [:register_and_log_in_user]

    setup %{conn: conn} do
      user = user_fixture()

      {:ok, app} = app_fixture(user, "http://localhost:8080/redirect")

      %{
        conn: conn,
        oauth_app: app
      }
    end

    test "GET /oauth/authorize", %{conn: conn, oauth_app: app} do
      conn =
        get(
          conn,
          Routes.oauth_path(conn, :authorize,
            client_id: app.client.id,
            client_secret: app.client.secret,
            scopes: "public",
            redirect_uri: URI.encode("http://localhost:8080/redirect"),
            response_type: "token"
          )
        )

      assert html_response(conn, 200) =~
               "Are you sure you wish to authorize Test Client to use your account? This application will be able to:"
    end

    test "POST /oauth/authorize deny", %{conn: conn, oauth_app: app} do
      conn =
        post(
          conn,
          Routes.oauth_path(conn, :process_authorize,
            client_id: app.client.id,
            client_secret: app.client.secret,
            scopes: "public",
            redirect_uri: URI.encode("http://localhost:8080/redirect"),
            response_type: "token",
            action: "deny"
          )
        )

      html_resp = html_response(conn, 302)
      assert html_resp =~ "You are being <a href="

      assert html_resp =~
               "error=access_denied&amp;error_description=The+resource+owner+or+authorization+server+denied+the+request."

      assert html_resp =~ ">redirected</a>."
    end

    test "POST /oauth/authorize authorize token", %{conn: conn, oauth_app: app} do
      conn =
        post(
          conn,
          Routes.oauth_path(conn, :process_authorize,
            client_id: app.client.id,
            client_secret: app.client.secret,
            scopes: "public",
            redirect_uri: URI.encode("http://localhost:8080/redirect"),
            response_type: "token",
            action: "authorize"
          )
        )

      html_resp = html_response(conn, 302)
      assert html_resp =~ "You are being <a href="
      assert html_resp =~ "http://localhost:8080/redirect#access_token="
      assert html_resp =~ "&amp;expires_in=86400"
      assert html_resp =~ ">redirected</a>."
    end

    test "POST /oauth/authorize authorize code", %{conn: conn, oauth_app: app} do
      conn =
        post(
          conn,
          Routes.oauth_path(conn, :process_authorize,
            client_id: app.client.id,
            client_secret: app.client.secret,
            scopes: "public",
            redirect_uri: URI.encode("http://localhost:8080/redirect"),
            response_type: "code",
            action: "authorize"
          )
        )

      html_resp = html_response(conn, 302)
      assert html_resp =~ "You are being <a href="
      assert html_resp =~ "http://localhost:8080/redirect?code="
      assert html_resp =~ ">redirected</a>."
    end

    test "POST /api/oauth/token authorize code", %{conn: conn, oauth_app: app} do
      conn =
        post(
          conn,
          Routes.oauth_path(conn, :process_authorize,
            client_id: app.client.id,
            client_secret: app.client.secret,
            scopes: "public",
            redirect_uri: URI.encode("http://localhost:8080/redirect"),
            response_type: "code",
            action: "authorize"
          )
        )

      assert %{"code" => code} = decode_resp_params(redirected_to(conn, 302))

      conn =
        post(
          conn,
          Routes.oauth_path(conn, :token,
            client_id: app.client.id,
            client_secret: app.client.secret,
            redirect_uri: URI.encode("http://localhost:8080/redirect"),
            grant_type: "authorization_code",
            code: code
          )
        )

      json_resp = json_response(conn, 200)
      assert %{"expires_in" => 86400, "token_type" => "bearer"} = json_resp
    end

    test "POST /api/oauth/token refresh authorize", %{conn: conn, oauth_app: app} do
      conn =
        post(
          conn,
          Routes.oauth_path(conn, :process_authorize,
            client_id: app.client.id,
            client_secret: app.client.secret,
            scopes: "public",
            redirect_uri: URI.encode("http://localhost:8080/redirect"),
            response_type: "code",
            action: "authorize"
          )
        )

      assert %{"code" => code} = decode_resp_params(redirected_to(conn, 302))

      conn =
        post(
          conn,
          Routes.oauth_path(conn, :token,
            client_id: app.client.id,
            client_secret: app.client.secret,
            redirect_uri: URI.encode("http://localhost:8080/redirect"),
            grant_type: "authorization_code",
            code: code
          )
        )

      assert %{
               "access_token" => access_token_one,
               "expires_in" => 86400,
               "refresh_token" => refresh_token_one,
               "token_type" => "bearer"
             } = json_response(conn, 200)

      conn =
        post(
          conn,
          Routes.oauth_path(conn, :token,
            client_id: app.client.id,
            client_secret: app.client.secret,
            refresh_token: refresh_token_one,
            grant_type: "refresh_token"
          )
        )

      assert %{
               "access_token" => access_token_two,
               "expires_in" => 86400,
               "refresh_token" => refresh_token_two,
               "token_type" => "bearer"
             } = json_response(conn, 200)

      assert access_token_one != access_token_two
      assert refresh_token_one != refresh_token_two
    end

    test "POST /api/oauth/introspec inspect token", %{conn: conn, oauth_app: app, user: user} do
      conn =
        post(
          conn,
          Routes.oauth_path(conn, :process_authorize,
            client_id: app.client.id,
            client_secret: app.client.secret,
            scopes: "public",
            redirect_uri: URI.encode("http://localhost:8080/redirect"),
            response_type: "code",
            action: "authorize"
          )
        )

      assert %{"code" => code} = decode_resp_params(redirected_to(conn, 302))

      conn =
        post(
          conn,
          Routes.oauth_path(conn, :token,
            client_id: app.client.id,
            client_secret: app.client.secret,
            redirect_uri: URI.encode("http://localhost:8080/redirect"),
            grant_type: "authorization_code",
            code: code
          )
        )

      assert %{
               "access_token" => access_token_one,
               "expires_in" => 86400,
               "token_type" => "bearer"
             } = json_response(conn, 200)

      conn =
        post(
          conn,
          Routes.oauth_path(conn, :introspect,
            client_id: app.client.id,
            client_secret: app.client.secret,
            token: access_token_one
          )
        )

      assert %{
               "active" => true,
               "username" => username,
               "sub" => user_id
             } = json_response(conn, 200)

      assert username == user.username
      assert user_id == user.id
    end

    test "POST /api/oauth/revoke token", %{conn: conn, oauth_app: app} do
      conn =
        post(
          conn,
          Routes.oauth_path(conn, :process_authorize,
            client_id: app.client.id,
            client_secret: app.client.secret,
            scopes: "public",
            redirect_uri: URI.encode("http://localhost:8080/redirect"),
            response_type: "code",
            action: "authorize"
          )
        )

      assert %{"code" => code} = decode_resp_params(redirected_to(conn, 302))

      conn =
        post(
          conn,
          Routes.oauth_path(conn, :token,
            client_id: app.client.id,
            client_secret: app.client.secret,
            redirect_uri: URI.encode("http://localhost:8080/redirect"),
            grant_type: "authorization_code",
            code: code
          )
        )

      assert %{
               "access_token" => access_token_one,
               "expires_in" => 86400,
               "refresh_token" => _,
               "token_type" => "bearer"
             } = json_response(conn, 200)

      conn =
        post(
          conn,
          Routes.oauth_path(conn, :revoke,
            client_id: app.client.id,
            client_secret: app.client.secret,
            token: access_token_one
          )
        )

      assert response(conn, 200)
    end
  end

  defp decode_resp_params(url) do
    url
    |> URI.parse()
    |> Map.get(:query)
    |> URI.decode_query()
  end
end
