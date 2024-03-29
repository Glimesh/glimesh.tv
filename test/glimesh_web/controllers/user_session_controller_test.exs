defmodule GlimeshWeb.UserSessionControllerTest do
  use GlimeshWeb.ConnCase, async: true

  import Glimesh.AccountsFixtures

  setup do
    %{user: user_fixture(), banned_user: banned_fixture()}
  end

  describe "GET /users/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, ~p"/users/log_in")
      response = html_response(conn, 200)
      assert response =~ "<h3>Login to our Alpha!</h3>"
      assert response =~ "Login</button>"
      assert response =~ "Register</a>"
    end

    test "redirects if already logged in", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> get(~p"/users/log_in")
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/log_in" do
    test "logs the user in with email", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"login" => user.email, "password" => valid_user_password(), "tfa" => nil}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ user.username
      assert response =~ "Settings"
      assert response =~ "Sign Out"
    end

    test "logs the user in with username", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"login" => user.username, "password" => valid_user_password(), "tfa" => nil}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ user.username
      assert response =~ "Settings"
      assert response =~ "Sign Out"
    end

    test "logs the user in with remember me", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{
            "login" => user.email,
            "password" => valid_user_password(),
            "remember_me" => "true",
            "tfa" => nil
          }
        })

      assert conn.resp_cookies["user_remember_me"]
      assert redirected_to(conn) =~ "/"
    end

    test "emits error message with invalid credentials", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"login" => user.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h3>Login to our Alpha!</h3>"
      assert response =~ "Invalid e-mail / username or password"
    end

    test "emits error message with banned user", %{conn: conn, banned_user: banned_user} do
      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{
            "login" => banned_user.email,
            "password" => valid_user_password(),
            "tfa" => nil
          }
        })

      response = html_response(conn, 200)
      assert response =~ "<h3>Login to our Alpha!</h3>"

      assert response =~
               "User account is banned. Please contact support at support@glimesh.tv for more information."
    end
  end

  describe "two factor workflow" do
    test "logs the user in with correct 2fa", %{conn: conn, user: user} do
      secret = Glimesh.Tfa.generate_secret(user.hashed_password)
      pin = Glimesh.Tfa.generate_totp(secret)
      password = valid_user_password()

      {:ok, user} = Glimesh.Accounts.update_tfa(user, pin, password, %{tfa_token: secret})

      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"login" => user.email, "password" => password}
        })

      assert get_session(conn, :tfa_user_id) == user.id
      response = html_response(conn, 200)
      assert response =~ "Enter your 2FA code!"

      conn =
        post(conn, ~p"/users/log_in_tfa", %{
          "user" => %{"tfa" => pin}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ user.username
      assert response =~ "Sign Out"
    end

    test "logs the user in within allowed 2fa time drift", %{conn: conn, user: user} do
      secret = Glimesh.Tfa.generate_secret(user.hashed_password)
      pin = Glimesh.Tfa.generate_totp(secret, 1)
      password = valid_user_password()

      {:ok, user} = Glimesh.Accounts.update_tfa(user, pin, password, %{tfa_token: secret})

      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"login" => user.email, "password" => password}
        })

      assert get_session(conn, :tfa_user_id) == user.id
      response = html_response(conn, 200)
      assert response =~ "Enter your 2FA code!"

      conn =
        post(conn, ~p"/users/log_in_tfa", %{
          "user" => %{"tfa" => pin}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) =~ "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ user.username
      assert response =~ "Sign Out"
    end

    test "errors and redirects on incorrect 2fa", %{conn: conn, user: user} do
      secret = Glimesh.Tfa.generate_secret(user.hashed_password)
      password = valid_user_password()

      {:ok, user} =
        Glimesh.Accounts.update_tfa(user, Glimesh.Tfa.generate_totp(secret), password, %{
          tfa_token: secret
        })

      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"login" => user.email, "password" => password}
        })

      conn =
        post(conn, ~p"/users/log_in_tfa", %{
          "user" => %{"tfa" => "123456"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h3>Login to our Alpha!</h3>"
      assert response =~ "Invalid 2FA code"
    end

    test "errors and redirects on 2fa drift steps out of bounds", %{conn: conn, user: user} do
      secret = Glimesh.Tfa.generate_secret(user.hashed_password)
      pin = Glimesh.Tfa.generate_totp(secret, 2)
      password = valid_user_password()

      {:ok, user} =
        Glimesh.Accounts.update_tfa(user, Glimesh.Tfa.generate_totp(secret), password, %{
          tfa_token: secret
        })

      conn =
        post(conn, ~p"/users/log_in", %{
          "user" => %{"login" => user.email, "password" => password}
        })

      conn =
        post(conn, ~p"/users/log_in_tfa", %{
          "user" => %{"tfa" => pin}
        })

      response = html_response(conn, 200)
      assert response =~ "<h3>Login to our Alpha!</h3>"
      assert response =~ "Invalid 2FA code"
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/users/log_out")
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/users/log_out")
      assert redirected_to(conn) == "/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
