defmodule GlimeshWeb.UserSettingsControllerTest do
  use GlimeshWeb.ConnCase, async: true

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :profile))
      response = html_response(conn, 200)
      assert response =~ "<h2 class=\"mt-4\">Your Profile</h2>"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.user_settings_path(conn, :profile))
      assert redirected_to(conn) == Routes.user_session_path(conn, :new)
    end
  end

  describe "PUT /users/settings/update_profile" do
    test "updates the social media profiles", %{conn: conn} do
      profile_conn =
        put(conn, Routes.user_settings_path(conn, :update_profile), %{
          "user" => %{
            "social_twitter" => "some-fake-twitter-url"
          }
        })

      assert redirected_to(profile_conn) == Routes.user_settings_path(conn, :profile)
      assert get_flash(profile_conn, :info) =~ "Profile updated successfully"

      response = html_response(get(conn, Routes.user_settings_path(conn, :profile)), 200)
      assert response =~ "some-fake-twitter-url"
    end

    test "does update displayname if case changes", %{conn: conn, user: user} do
      profile_conn =
        put(conn, Routes.user_settings_path(conn, :update_profile), %{
          "user" => %{
            "displayname" => String.upcase(user.username)
          }
        })

      assert redirected_to(profile_conn) == Routes.user_settings_path(conn, :profile)
      assert get_flash(profile_conn, :info) =~ "Profile updated successfully"

      response = html_response(get(conn, Routes.user_settings_path(conn, :profile)), 200)
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
      assert response =~ "Display name must match username"
    end
  end
end
