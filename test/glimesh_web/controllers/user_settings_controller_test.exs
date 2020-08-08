defmodule GlimeshWeb.UserSettingsControllerTest do
  use GlimeshWeb.ConnCase, async: true

  alias Glimesh.Accounts
  import Glimesh.AccountsFixtures

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h2 class=\"mt-4\">Your Profile</h2>"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  describe "PUT /users/settings/update_profile" do
    test "updates the social media profiles", %{conn: conn, user: user} do
      profile_conn =
        put(conn, Routes.user_settings_path(conn, :update_profile), %{
          "user" => %{
            "social_twitter" => "some-fake-twitter-url"
          }
        })

      assert redirected_to(profile_conn) == Routes.user_settings_path(conn, :edit)
      assert get_flash(profile_conn, :info) =~ "Profile updated successfully"

      response = html_response(get(conn, Routes.user_settings_path(conn, :edit)), 200)
      assert response =~ "some-fake-twitter-url"
    end

    test "does update displayname if case changes", %{conn: conn, user: user} do
      profile_conn =
        put(conn, Routes.user_settings_path(conn, :update_profile), %{
          "user" => %{
            "displayname" => String.upcase(user.username)
          }
        })

      assert redirected_to(profile_conn) == Routes.user_settings_path(conn, :edit)
      assert get_flash(profile_conn, :info) =~ "Profile updated successfully"

      response = html_response(get(conn, Routes.user_settings_path(conn, :edit)), 200)
      assert response =~ String.upcase(user.username)
    end

    test "does not update displayname if it does not match username", %{conn: conn, user: user} do
      profile_conn =
        put(conn, Routes.user_settings_path(conn, :update_profile), %{
          "user" => %{
            "displayname" => user.username <> "f"
          }
        })

      response = html_response(profile_conn, 200)
      assert response =~ "<h2 class=\"mt-4\">Your Profile</h2>"
      assert response =~ "Display name must match Username"
    end
  end

  describe "PUT /users/settings/update_password" do
    test "updates the user password and resets tokens", %{conn: conn, user: user} do
      new_password_conn =
        put(conn, Routes.user_settings_path(conn, :update_password), %{
          "current_password" => valid_user_password(),
          "user" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.user_settings_path(conn, :edit)
      assert get_session(new_password_conn, :user_token) != get_session(conn, :user_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.user_settings_path(conn, :update_password), %{
          "current_password" => "invalid",
          "user" => %{
            "password" => "short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h2 class=\"mt-4\">Your Profile</h2>"
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
        put(conn, Routes.user_settings_path(conn, :update_email), %{
          "current_password" => valid_user_password(),
          "user" => %{"email" => unique_user_email()}
        })

      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "A link to confirm your e-mail"
      assert Accounts.get_user_by_email(user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.user_settings_path(conn, :update_email), %{
          "current_password" => "invalid",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h2 class=\"mt-4\">Your Profile</h2>"
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
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "E-mail changed successfully"
      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end
end
