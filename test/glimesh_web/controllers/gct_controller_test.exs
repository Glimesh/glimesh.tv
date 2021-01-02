defmodule GlimeshWeb.GctControllerTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures

  describe "GET /gct" do
    setup :register_and_log_in_gct_user

    test "show index page", %{conn: conn} do
      conn = get(conn, Routes.gct_path(conn, :index))
      assert html_response(conn, 200) =~ "Glimesh Community Team Dashboard"
    end
  end

  describe "GET /gct non-gct" do
    test "redirect user", %{conn: conn} do
      conn = get(conn, Routes.gct_path(conn, :index))
      assert html_response(conn, 302) =~ "You are being"
    end
  end

  describe "GET /gct without tfa" do
    setup :register_and_log_in_gct_user_without_tfa

    test "redirect user", %{conn: conn} do
      conn = get(conn, Routes.gct_path(conn, :index))
      assert html_response(conn, 302) =~ "You are being"
    end
  end

  describe "GET /gct/lookup/username" do
    setup :register_and_log_in_gct_user

    test "valid user returns information", %{conn: conn} do
      lookup_user = user_fixture()
      conn = get(conn, Routes.gct_path(conn, :username_lookup, query: lookup_user.username))
      assert html_response(conn, 200) =~ "Information for " <> lookup_user.displayname
    end

    test "invalid user returns an invalid user page", %{conn: conn} do
      conn = get(conn, Routes.gct_path(conn, :username_lookup, query: "invalid_user"))
      assert html_response(conn, 200) =~ "Does not exist"
    end
  end

  describe "GET /gct/lookup/channel" do
    setup :register_and_log_in_gct_user

    test "valid channel returns information", %{conn: conn} do
      streamer = streamer_fixture()

      conn = get(conn, Routes.gct_path(conn, :channel_lookup, query: streamer.username))

      assert html_response(conn, 200) =~ "Information for " <> streamer.displayname
    end

    test "invalid channel returns an invalid channel page", %{conn: conn} do
      conn = get(conn, Routes.gct_path(conn, :channel_lookup, query: "@"))
      assert html_response(conn, 200) =~ "Does not exist"
    end
  end

  describe "GET /gct/edit/:username" do
    setup :register_and_log_in_gct_user

    test "valid user returns edit page", %{conn: conn} do
      valid_user = user_fixture()
      conn = get(conn, Routes.gct_path(conn, :edit_user, valid_user.username))
      assert html_response(conn, 200) =~ valid_user.displayname
    end

    test "invalid user returns invalid user page", %{conn: conn} do
      conn = get(conn, Routes.gct_path(conn, :edit_user, "invalid_user"))
      assert html_response(conn, 200) =~ "Does not exist"
    end

    test "does update username if valid", %{conn: conn} do
      user = user_fixture()

      user_conn =
        put(conn, Routes.gct_path(conn, :update_user, user.username), %{
          "user" => %{
            "username" => "valid_username"
          }
        })

      assert redirected_to(user_conn) == Routes.gct_path(conn, :edit_user, "valid_username")
      assert get_flash(user_conn, :info) =~ "User updated successfully"

      resp = html_response(get(conn, Routes.gct_path(conn, :edit_user, "valid_username")), 200)
      assert resp =~ "valid_username"
    end

    test "doesn't update username if invalid", %{conn: conn} do
      user = user_fixture()

      user_conn =
        put(conn, Routes.gct_path(conn, :update_user, user.username), %{
          "user" => %{
            "username" => "a"
          }
        })

      resp = html_response(user_conn, 200)
      assert resp =~ "Must be at least 3 characters"
    end

    test "does update email if valid", %{conn: conn} do
      user = user_fixture()

      user_conn =
        put(conn, Routes.gct_path(conn, :update_user, user.username), %{
          "user" => %{
            "email" => "valid@email.com"
          }
        })

      assert redirected_to(user_conn) == Routes.gct_path(conn, :edit_user, user.username)
      assert get_flash(user_conn, :info) =~ "User updated successfully"

      resp = html_response(get(conn, Routes.gct_path(conn, :edit_user, user.username)), 200)
      assert resp =~ "valid@email.com"
    end

    test "doesn't update email if invalid", %{conn: conn} do
      user = user_fixture()

      user_conn =
        put(conn, Routes.gct_path(conn, :update_user, user.username), %{
          "user" => %{
            "email" => "invalid email"
          }
        })

      resp = html_response(user_conn, 200)
      assert resp =~ "must have the @ sign and no spaces"
    end
  end

  describe "GET /gct/edit/profile/:username" do
    setup :register_and_log_in_gct_user

    test "valid user returns edit profile page", %{conn: conn} do
      valid_user = user_fixture()
      conn = get(conn, Routes.gct_path(conn, :edit_user_profile, valid_user.username))
      assert html_response(conn, 200) =~ valid_user.username
    end

    test "invalid user returns invalid user page", %{conn: conn} do
      conn = get(conn, Routes.gct_path(conn, :edit_user_profile, "invalid_user"))
      assert html_response(conn, 200) =~ "Does not exist"
    end

    test "updates the social media profiles", %{conn: conn} do
      valid_user = user_fixture()

      profile_conn =
        put(conn, Routes.gct_path(conn, :update_user_profile, valid_user.username), %{
          "user" => %{
            "social_twitter" => "some-fake-twitter-url",
            "social_discord" => "some-fake-discord-url",
            "social_instagram" => "some-fake-insta-url",
            "social_youtube" => "some-fake-yt-url"
          }
        })

      assert redirected_to(profile_conn) ==
               Routes.gct_path(conn, :edit_user_profile, valid_user.username)

      assert get_flash(profile_conn, :info) =~ "User updated successfully"

      response =
        html_response(
          get(conn, Routes.gct_path(conn, :edit_user_profile, valid_user.username)),
          200
        )

      assert response =~ "some-fake-twitter-url"
      assert response =~ "some-fake-discord-url"
      assert response =~ "some-fake-insta-url"
      assert response =~ "some-fake-yt-url"
    end

    test "does update displayname if case changes", %{conn: conn} do
      user = user_fixture()

      profile_conn =
        put(conn, Routes.gct_path(conn, :update_user_profile, user.username), %{
          "user" => %{
            "displayname" => String.upcase(user.username)
          }
        })

      assert redirected_to(profile_conn) ==
               Routes.gct_path(conn, :edit_user_profile, user.username)

      assert get_flash(profile_conn, :info) =~ "User updated successfully"

      response =
        html_response(get(conn, Routes.gct_path(conn, :edit_user_profile, user.username)), 200)

      assert response =~ String.upcase(user.username)
    end

    test "does not update displayname if it does not match username", %{conn: conn} do
      user = user_fixture()

      profile_conn =
        put(conn, Routes.gct_path(conn, :update_user_profile, user.username), %{
          "user" => %{
            "displayname" => user.username <> "f"
          }
        })

      response = html_response(profile_conn, 200)
      assert response =~ "Display name must match username"
    end
  end

  describe "GET /gct/edit/channel/:username" do
    setup :register_and_log_in_gct_user

    test "valid user returns edit page", %{conn: conn} do
      streamer = streamer_fixture()
      conn = get(conn, Routes.gct_path(conn, :edit_channel, streamer.channel.id))
      assert html_response(conn, 200) =~ streamer.username
    end

    test "invalid user returns invalid channel page", %{conn: conn} do
      conn = get(conn, Routes.gct_path(conn, :edit_channel, 0))
      assert html_response(conn, 200) =~ "Does not exist"
    end

    test "updating title actually updates it", %{conn: conn} do
      %{channel: channel} = streamer_fixture()

      channel_conn =
        put(conn, Routes.gct_path(conn, :update_channel, channel.id), %{
          "channel" => %{
            "title" => "New title"
          }
        })

      assert redirected_to(channel_conn) == Routes.gct_path(conn, :edit_channel, channel.id)
      assert get_flash(channel_conn, :info) =~ "Channel updated successfully"

      resp = html_response(get(conn, Routes.gct_path(conn, :edit_channel, channel.id)), 200)
      assert resp =~ "New title"
    end
  end
end
