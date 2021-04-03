defmodule GlimeshWeb.Api.OauthTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures

  describe "authorize oauth2" do
    setup [:register_and_log_in_user]

    setup %{conn: conn} do
      user = user_fixture()

      {:ok, app} =
        Glimesh.Apps.create_app(user, %{
          name: "some name",
          description: "some description",
          homepage_url: "https://glimesh.tv/",
          oauth_application: %{
            redirect_uri: "http://localhost:8080/redirect"
          }
        })

      %{
        conn: conn,
        oauth_app: app
      }
    end

    test "GET /oauth/authorize", %{conn: conn, oauth_app: app} do
      conn = get(conn, Routes.authorization_path(conn, :new, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, scopes: "public", redirect_uri: URI.encode("http://localhost:8080/redirect"), response_type: "token"))
      assert html_response(conn, 200) =~ "Are you sure you wish to authorize some name to use your account? This application will be able to:"
    end

    test "POST /oauth/authorize deny", %{conn: conn, oauth_app: app} do
      conn = post(conn, Routes.authorization_path(conn, :create, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, scopes: "public", redirect_uri: URI.encode("http://localhost:8080/redirect"), response_type: "token", action: "deny"))
      html_resp = html_response(conn, 302)
      assert html_resp =~ "You are being <a href="
      assert html_resp =~ "http://localhost:8080/redirect?error=access_denied&amp;error_description=The+resource+owner+or+authorization+server+denied+the+request."
      assert html_resp =~ ">redirected</a>."
    end

    test "POST /oauth/authorize authorize token", %{conn: conn, oauth_app: app} do
      conn = post(conn, Routes.authorization_path(conn, :create, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, scopes: "public", redirect_uri: URI.encode("http://localhost:8080/redirect"), response_type: "token", action: "authorize"))
      html_resp = html_response(conn, 302)
      assert html_resp =~ "You are being <a href="
      assert html_resp =~ "http://localhost:8080/redirect#access_token="
      assert html_resp =~ "&amp;expires_in=604800&amp;scope=public&amp;token_type=bearer"
      assert html_resp =~ ">redirected</a>."
    end

    test "POST /oauth/authorize authorize code", %{conn: conn, oauth_app: app} do
      conn = post(conn, Routes.authorization_path(conn, :create, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, scopes: "public", redirect_uri: URI.encode("http://localhost:8080/redirect"), response_type: "code", action: "authorize"))
      html_resp = html_response(conn, 302)
      assert html_resp =~ "You are being <a href="
      assert html_resp =~ "http://localhost:8080/redirect?code="
      assert html_resp =~ ">redirected</a>."
    end

    test "POST /api/oauth/token authorize code", %{conn: conn, oauth_app: app} do
      conn = post(conn, Routes.authorization_path(conn, :create, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, scopes: "public", redirect_uri: URI.encode("urn:ietf:wg:oauth:2.0:oob"), response_type: "code", action: "authorize"))
      assert %{"code" => code} = json_response(conn, 200)
      conn = post(conn, Routes.token_path(conn, :create, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, redirect_uri: URI.encode("urn:ietf:wg:oauth:2.0:oob"), grant_type: "authorization_code", code: code))
      json_resp = json_response(conn, 200)
      assert %{"expires_in" => 21600, "scope" => "public", "token_type" => "bearer"} = json_resp
    end

    test "POST /api/oauth/token refresh authorize", %{conn: conn, oauth_app: app} do
      conn = post(conn, Routes.authorization_path(conn, :create, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, scopes: "public", redirect_uri: URI.encode("urn:ietf:wg:oauth:2.0:oob"), response_type: "code", action: "authorize"))
      assert %{"code" => code} = json_response(conn, 200)
      conn = post(conn, Routes.token_path(conn, :create, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, redirect_uri: URI.encode("urn:ietf:wg:oauth:2.0:oob"), grant_type: "authorization_code", code: code))
      assert %{"access_token" => access_token_one, "created_at" => created_at_one, "expires_in" => 21600, "refresh_token" => refresh_token_one, "scope" => "public", "token_type" => "bearer"} = json_response(conn, 200)
      conn = post(conn, Routes.token_path(conn, :create, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, refresh_token: refresh_token_one, grant_type: "refresh_token"))
      assert %{"access_token" => access_token_two, "created_at" => created_at_two, "expires_in" => 21600, "refresh_token" => refresh_token_two, "scope" => "public", "token_type" => "bearer"} = json_response(conn, 200)
      #! this test checks wrong at the current time due to the oauth lib doing the wrong thing when `"grant_type": "refresh_token"` is called
      # TODO fix this test to check if token one and two does not match once oauth is written from ground up
      assert access_token_one == access_token_two
      assert created_at_one == created_at_two
      assert refresh_token_one == refresh_token_two
    end

    test "POST /api/oauth/introspec inspect token", %{conn: conn, oauth_app: app, user: user} do
      conn = post(conn, Routes.authorization_path(conn, :create, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, scopes: "public", redirect_uri: URI.encode("urn:ietf:wg:oauth:2.0:oob"), response_type: "code", action: "authorize"))
      assert %{"code" => code} = json_response(conn, 200)
      conn = post(conn, Routes.token_path(conn, :create, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, redirect_uri: URI.encode("urn:ietf:wg:oauth:2.0:oob"), grant_type: "authorization_code", code: code))
      assert %{"access_token" => access_token_one,"expires_in" => 21600, "scope" => "public", "token_type" => "bearer"} = json_response(conn, 200)
      conn = post(conn, Routes.token_path(conn, :introspec, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, token: access_token_one, grant_type: "refresh_token"))
      assert %{"active" => true, "scopes" => "public", "username" => username, "user_id" => user_id} = json_response(conn, 200)
      assert username == user.username
      assert user_id == user.id
    end

    test "POST /api/oauth/revoke token", %{conn: conn, oauth_app: app} do
      conn = post(conn, Routes.authorization_path(conn, :create, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, scopes: "public", redirect_uri: URI.encode("urn:ietf:wg:oauth:2.0:oob"), response_type: "code", action: "authorize"))
      assert %{"code" => code} = json_response(conn, 200)
      conn = post(conn, Routes.token_path(conn, :create, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, redirect_uri: URI.encode("urn:ietf:wg:oauth:2.0:oob"), grant_type: "authorization_code", code: code))
      assert %{"access_token" => access_token_one, "created_at" => created_at_one, "expires_in" => 21600, "refresh_token" => refresh_token_one, "scope" => "public", "token_type" => "bearer"} = json_response(conn, 200)
      conn = post(conn, Routes.token_path(conn, :revoke, client_id: app.oauth_application.uid, client_secret: app.oauth_application.secret, token: access_token_one))
      assert json_response(conn, 200)
    end
  end
end
