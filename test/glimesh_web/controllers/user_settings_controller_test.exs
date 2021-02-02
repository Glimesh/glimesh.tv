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

  describe "GET /user/settings/stream" do
    setup :register_and_log_in_streamer

    test "renders channel settings page when you have a channel", %{conn: conn} do
      conn = get(conn, Routes.user_settings_path(conn, :stream))
      response = html_response(conn, 200)
      assert response =~ "Channel title"
    end
  end

  describe "PUT /user/settings/create_channel" do
    test "creates channel when user doesn't have one", %{conn: conn} do
      conn = put(conn, Routes.user_settings_path(conn, :create_channel))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :stream)
    end
  end

  describe "PUT /user/settings/delete_channel" do
    setup :register_and_log_in_streamer

    test "deletes the channel if the user has one", %{conn: conn} do
      conn = put(conn, Routes.user_settings_path(conn, :delete_channel))
      assert redirected_to(conn) == Routes.user_settings_path(conn, :stream)
    end
  end

  describe "PUT /user/settings/update_channel" do
    setup :register_and_log_in_streamer

    test "updates the title", %{conn: conn} do
      channel_conn =
        put(conn, Routes.user_settings_path(conn, :update_channel), %{
          "channel" => %{
            "title" => "some new title"
          }
        })

      assert redirected_to(channel_conn) == Routes.user_settings_path(conn, :stream)
      assert get_flash(channel_conn, :info) =~ "Stream settings updated successfully"

      response = html_response(get(conn, Routes.user_settings_path(conn, :stream)), 200)
      assert response =~ "some new title"
    end

    test "invalid title doesn't update", %{conn: conn} do
      channel_conn =
        put(conn, Routes.user_settings_path(conn, :update_channel), %{
          "channel" => %{
            "title" => """
            u06rnPOWfai1tyO79N9B2SF2sIxetMqkWbDHWeMCdcrHMtH5IorWQvZeF4F6ZGaHwx1ABn3UqFE4UkVlFZLgVjWodXZfRBEUE5bjehnnARY8M
            z2161na4akcHU3hMxfgHgCFuTplOwXRPxWuuxIiko26tMvTXtDeRhh6u4Cj8euSMc6pXCpkmR6RsxajRi21scXhIbsVrUNmPnoMrVpAlWEMM7fCdMbNXXjFhyki8L9EZjYRmMxErZAqykr
            """

            # 251 character title
          }
        })

      response = html_response(channel_conn, 200)
      assert response =~ "Must not exceed 250 characters"
    end

    test "handles no tags", %{conn: conn} do
      channel_conn =
        put(conn, Routes.user_settings_path(conn, :update_channel), %{
          "channel" => %{
            "tags" => ""
          }
        })

      assert redirected_to(channel_conn) == Routes.user_settings_path(conn, :stream)
      assert get_flash(channel_conn, :info) =~ "Stream settings updated successfully"

      response = html_response(get(conn, Routes.user_settings_path(conn, :stream)), 200)
      refute response =~ "Digital Media"
    end

    test "puts tags", %{conn: conn, channel: channel} do
      tags_input =
        Jason.encode!([
          %{category_id: channel.category_id, value: "Digital Media"},
          %{category_id: channel.category_id, value: "some name"}
        ])

      channel_conn =
        put(conn, Routes.user_settings_path(conn, :update_channel), %{
          "channel" => %{
            "tags" => tags_input
          }
        })

      assert redirected_to(channel_conn) == Routes.user_settings_path(conn, :stream)
      assert get_flash(channel_conn, :info) =~ "Stream settings updated successfully"

      response = html_response(get(conn, Routes.user_settings_path(conn, :stream)), 200)
      assert response =~ "Digital Media"
      assert response =~ "some name"
    end
  end

  describe "PUT /users/settings/update_profile" do
    test "updates the social media profiles", %{conn: conn} do
      profile_conn =
        put(conn, Routes.user_settings_path(conn, :update_profile), %{
          "user" => %{
            "social_discord" => "some-fake-discord-url"
          }
        })

      assert redirected_to(profile_conn) == Routes.user_settings_path(conn, :profile)
      assert get_flash(profile_conn, :info) =~ "Profile updated successfully"

      response = html_response(get(conn, Routes.user_settings_path(conn, :profile)), 200)
      assert response =~ "some-fake-discord-url"
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
