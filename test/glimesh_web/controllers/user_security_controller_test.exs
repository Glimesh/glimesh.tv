defmodule GlimeshWeb.UserSecurityControllerTest do
  use GlimeshWeb.ConnCase, async: true

  alias Glimesh.Accounts
  import Glimesh.AccountsFixtures

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, ~p"/users/settings/security")
      response = html_response(conn, 200)
      assert response =~ "Security"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, ~p"/users/settings/security")
      assert redirected_to(conn) == ~p"/users/log_in"
    end

    test "shows the tfa image", %{conn: conn} do
      conn = get(conn, ~p"/users/settings/get_tfa")
      assert get_resp_header(conn, "content-type") == ["image/png; charset=utf-8"]
    end

    test "shows the tfa image if a tfa_secret already exists in the session", %{conn: conn} do
      conn = conn |> put_session(:tfa_secret, "test")
      conn = get(conn, ~p"/users/settings/get_tfa")
      assert get_session(conn, :tfa_secret) == "test"
      assert get_resp_header(conn, "content-type") == ["image/png; charset=utf-8"]
    end
  end

  describe "PUT /users/settings/update_password" do
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, ~p"/users/settings/update_password", %{
          "current_password" => valid_user_password(),
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == ~p"/users/settings/security"
      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)

      assert Phoenix.Flash.get(new_password_conn.assigns.flash, :info) =~
               "Password updated successfully"

      assert Accounts.get_user_by_login_and_password(user.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, ~p"/users/settings/update_password", %{
          "current_password" => "invalid",
          "user" => %{
            "password" => "short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "Security"
      assert response =~ "Must be at least 8 characters"
      assert response =~ "Password does not match"
      assert response =~ "Invalid Password"

      assert get_session(old_password_conn, :user_token) == get_session(conn, :user_token)
    end
  end

  describe "PUT /users/settings/update_email" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user} do
      conn =
        put(conn, ~p"/users/settings/update_email", %{
          "current_password" => valid_user_password(),
          "user" => %{"email" => unique_user_email()}
        })

      assert redirected_to(conn) == ~p"/users/settings/security"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "A link to confirm your email"
      assert Accounts.get_user_by_email(user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, ~p"/users/settings/update_email", %{
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "Security"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "Invalid Password"
    end
  end

  describe "GET /users/settings/confirm_email/:token" do
    setup %{user: user} do
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      conn = get(conn, ~p"/users/settings/confirm_email/#{token}")
      assert redirected_to(conn) == ~p"/users/settings/security"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Email changed successfully"
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      conn = get(conn, ~p"/users/settings/confirm_email/#{token}")
      assert redirected_to(conn) == ~p"/users/settings/security"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, ~p"/users/settings/confirm_email/oops")
      assert redirected_to(conn) == ~p"/users/settings/security"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"

      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, ~p"/users/settings/confirm_email/#{token}")
      assert redirected_to(conn) == ~p"/users/log_in"
    end
  end
end
