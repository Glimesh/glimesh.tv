defmodule GlimeshWeb.UserSettingsControllerTest do
  use GlimeshWeb.ConnCase, async: true

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, ~p"/users/settings/profile")
      response = html_response(conn, 200)
      assert response =~ "<h2 class=\"mt-4\">Your Profile</h2>"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, ~p"/users/settings/profile")
      assert redirected_to(conn) == ~p"/users/log_in"
    end
  end

  describe "GET /user/settings/stream" do
    setup :register_and_log_in_streamer

    test "renders channel settings page when you have a channel", %{conn: conn} do
      conn = get(conn, ~p"/users/settings/stream")
      response = html_response(conn, 200)
      assert response =~ "Channel title"
    end
  end

  describe "PUT /user/settings/create_channel" do
    test "creates channel when user doesn't have one", %{conn: conn} do
      conn = put(conn, ~p"/users/settings/create_channel")
      assert redirected_to(conn) == ~p"/users/settings/stream"
    end
  end

  describe "PUT /user/settings/delete_channel" do
    setup :register_and_log_in_streamer

    test "deletes the channel if the user has one", %{conn: conn} do
      conn = put(conn, ~p"/users/settings/delete_channel")
      assert redirected_to(conn) == ~p"/users/settings/stream"
    end
  end

  describe "PUT /user/settings/update_channel" do
    setup :register_and_log_in_streamer

    test "updates the title", %{conn: conn} do
      channel_conn =
        put(conn, ~p"/users/settings/update_channel", %{
          "channel" => %{
            "title" => "some new title"
          }
        })

      assert redirected_to(channel_conn) == ~p"/users/settings/stream"

      assert Phoenix.Flash.get(channel_conn.assigns.flash, :info) =~
               "Stream settings updated successfully"

      response = html_response(get(conn, ~p"/users/settings/stream"), 200)
      assert response =~ "some new title"
    end

    test "invalid title doesn't update", %{conn: conn} do
      channel_conn =
        put(conn, ~p"/users/settings/update_channel", %{
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
        put(conn, ~p"/users/settings/update_channel", %{
          "channel" => %{
            "tags" => ""
          }
        })

      assert redirected_to(channel_conn) == ~p"/users/settings/stream"

      assert Phoenix.Flash.get(channel_conn.assigns.flash, :info) =~
               "Stream settings updated successfully"

      response = html_response(get(conn, ~p"/users/settings/stream"), 200)
      refute response =~ "Digital Media"
    end

    test "puts tags", %{conn: conn, channel: channel} do
      tags_input =
        Jason.encode!([
          %{category_id: channel.category_id, value: "Digital Media"},
          %{category_id: channel.category_id, value: "some name"}
        ])

      channel_conn =
        put(conn, ~p"/users/settings/update_channel", %{
          "channel" => %{
            "tags" => tags_input
          }
        })

      assert redirected_to(channel_conn) == ~p"/users/settings/stream"

      assert Phoenix.Flash.get(channel_conn.assigns.flash, :info) =~
               "Stream settings updated successfully"

      response = html_response(get(conn, ~p"/users/settings/stream"), 200)
      assert response =~ "Digital Media"
      assert response =~ "some name"
    end

    test "handles no subcategory", %{conn: conn} do
      channel_conn =
        put(conn, ~p"/users/settings/update_channel", %{
          "channel" => %{
            "subcategory" => ""
          }
        })

      assert redirected_to(channel_conn) == ~p"/users/settings/stream"

      assert Phoenix.Flash.get(channel_conn.assigns.flash, :info) =~
               "Stream settings updated successfully"

      response = html_response(get(conn, ~p"/users/settings/stream"), 200)
      refute response =~ "Some Subcategory"
    end

    test "puts subcategories", %{conn: conn, channel: channel} do
      input =
        Jason.encode!([
          %{category_id: channel.category_id, value: "Some Subcategory"}
        ])

      channel_conn =
        put(conn, ~p"/users/settings/update_channel", %{
          "channel" => %{
            "subcategory" => input
          }
        })

      assert redirected_to(channel_conn) == ~p"/users/settings/stream"

      assert Phoenix.Flash.get(channel_conn.assigns.flash, :info) =~
               "Stream settings updated successfully"

      response = html_response(get(conn, ~p"/users/settings/stream"), 200)
      assert response =~ "Some Subcategory"
    end

    test "using an existing subcategory doesn't recreate it", %{conn: conn, channel: channel} do
      {:ok, existing_sub} =
        Glimesh.ChannelCategories.create_subcategory(%{
          category_id: channel.category_id,
          name: "Some Subcategory"
        })

      input =
        Jason.encode!([
          %{category_id: channel.category_id, value: "Some Subcategory"}
        ])

      channel_conn =
        put(conn, ~p"/users/settings/update_channel", %{
          "channel" => %{
            "subcategory" => input
          }
        })

      assert redirected_to(channel_conn) == ~p"/users/settings/stream"

      assert Phoenix.Flash.get(channel_conn.assigns.flash, :info) =~
               "Stream settings updated successfully"

      response = html_response(get(conn, ~p"/users/settings/stream"), 200)
      assert response =~ "Some Subcategory"

      new_channel = Glimesh.ChannelLookups.get_channel(channel.id)
      assert new_channel.subcategory.id == existing_sub.id
    end
  end

  describe "PUT /users/settings/update_profile" do
    test "updates the social media profiles", %{conn: conn} do
      profile_conn =
        put(conn, ~p"/users/settings/update_profile", %{
          "user" => %{
            "social_discord" => "inviteurl"
          }
        })

      assert redirected_to(profile_conn) == ~p"/users/settings/profile"

      assert Phoenix.Flash.get(profile_conn.assigns.flash, :info) =~
               "Profile updated successfully"

      response = html_response(get(conn, ~p"/users/settings/profile"), 200)
      assert response =~ "inviteurl"
    end

    test "does update displayname if case changes", %{conn: conn, user: user} do
      profile_conn =
        put(conn, ~p"/users/settings/update_profile", %{
          "user" => %{
            "displayname" => String.upcase(user.username)
          }
        })

      assert redirected_to(profile_conn) == ~p"/users/settings/profile"

      assert Phoenix.Flash.get(profile_conn.assigns.flash, :info) =~
               "Profile updated successfully"

      response = html_response(get(conn, ~p"/users/settings/profile"), 200)
      assert response =~ String.upcase(user.username)
    end

    test "does not update displayname if it does not match username", %{conn: conn, user: user} do
      profile_conn =
        put(conn, ~p"/users/settings/update_profile", %{
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
