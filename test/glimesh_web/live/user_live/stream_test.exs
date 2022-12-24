defmodule GlimeshWeb.UserLive.StreamTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  import Phoenix.LiveViewTest

  describe "Stream Page" do
    setup do
      streamer = streamer_fixture()

      %{
        channel: streamer.channel,
        streamer: streamer
      }
    end

    test "shows a video player", %{conn: conn, streamer: streamer} do
      {:ok, _, html} = live(conn, Routes.user_stream_path(conn, :index, streamer.username))

      assert html =~ "<video"
      assert html =~ streamer.displayname
    end

    test "has metadata about the offline stream", %{conn: conn, streamer: streamer} do
      {:ok, _, html} = live(conn, Routes.user_stream_path(conn, :index, streamer.username))

      assert html =~ "#{streamer.displayname}&#39;s Glimesh Channel"
    end

    test "has metadata about the live stream", %{conn: conn, channel: channel, streamer: streamer} do
      {:ok, _} = Glimesh.Streams.start_stream(channel)
      {:ok, _, html} = live(conn, Routes.user_stream_path(conn, :index, streamer.username))

      assert html =~ "#{streamer.displayname} is streaming live on Glimesh.tv!"
    end
  end

  describe "Mature Content Stream Page" do
    setup do
      streamer = streamer_fixture(%{}, %{mature_content: true})

      %{
        channel: streamer.channel,
        streamer: streamer
      }
    end

    test "prompts for mature content warning", %{conn: conn, streamer: streamer} do
      {:ok, view, html} = live(conn, Routes.user_stream_path(conn, :index, streamer.username))

      assert html =~ "Mature Content Warning"
      refute html =~ "<video"

      page = view |> element("button", "Agree & View Channel") |> render_click()
      assert page =~ "<video"
    end
  end

  describe "Edge Routing" do
    setup do
      Glimesh.Janus.create_edge_route(%{
        hostname: "some-de-server",
        url: "https://some-de-server/janus",
        priority: 1.0,
        available: true,
        country_codes: ["DE", "AT"]
      })

      Glimesh.Janus.create_edge_route(%{
        hostname: "some-us-server",
        url: "https://some-us-server/janus",
        priority: 1.1,
        available: true,
        country_codes: ["US", "MX"]
      })

      streamer = streamer_fixture()

      %{
        channel: streamer.channel,
        streamer: streamer
      }
    end

    test "gets sent to the correct edge location", %{conn: conn, streamer: streamer} do
      conn =
        conn
        |> Plug.Conn.put_req_header(
          "cf-ipcountry",
          "DE"
        )

      {:ok, view, _} = live(conn, Routes.user_stream_path(conn, :index, streamer.username))

      html = render_click(view, "toggle_debug")

      assert html =~ "Debug Information"
      assert html =~ "some-de-server"
      assert html =~ "https://some-de-server/janus"
    end
  end

  describe "lost packets event" do
    setup do
      streamer = streamer_fixture()

      %{
        channel: streamer.channel,
        streamer: streamer
      }
    end

    test "lost_packets doesn't crash", %{conn: conn, streamer: streamer} do
      {:ok, view, _} = live(conn, Routes.user_stream_path(conn, :index, streamer.username))

      params = %{
        "uplink" => "doesn't matter",
        "lostPackets" => 1
      }

      render_click(view, "toggle_debug")
      render_click(view, "lost_packets", params)

      # event = GlimeshWeb.UserLive.Stream.handle_event("lost_packets", params, socket)
      assert render(view) =~ "lost_packets"
    end

    test "lost_packets safely recovers from nil", %{conn: conn, streamer: streamer} do
      {:ok, view, _} = live(conn, Routes.user_stream_path(conn, :index, streamer.username))

      params = %{
        "uplink" => "doesn't matter",
        "lostPackets" => nil
      }

      render_click(view, "toggle_debug")
      render_click(view, "lost_packets", params)

      # event = GlimeshWeb.UserLive.Stream.handle_event("lost_packets", params, socket)
      assert render(view) =~ "lost_packets"
    end

    test "lost_packets safely recovers from garbage", %{conn: conn, streamer: streamer} do
      {:ok, view, _} = live(conn, Routes.user_stream_path(conn, :index, streamer.username))

      params = %{
        "uplink" => "doesn't matter",
        "lostPackets" => <<123, 123, 123, 123, 123, 123>>
      }

      render_click(view, "toggle_debug")
      render_click(view, "lost_packets", params)

      # event = GlimeshWeb.UserLive.Stream.handle_event("lost_packets", params, socket)
      assert render(view) =~ "lost_packets"
    end
  end

  describe "hosting information" do
    setup do
      streamer = streamer_fixture()
      host = streamer_fixture()
      {:ok, _} = Glimesh.Streams.start_stream(streamer.channel)

      Glimesh.Repo.insert(%Glimesh.Streams.ChannelHosts{
        hosting_channel_id: host.channel.id,
        target_channel_id: streamer.channel.id,
        status: "hosting"
      })

      %{
        channel: streamer.channel,
        streamer: streamer,
        host: host
      }
    end

    test "shows hosted message", %{conn: conn, streamer: streamer, host: host} do
      path =
        get(conn, Routes.user_stream_path(conn, :index, streamer.username), host: host.username)

      assert {:ok, view, html} = live(path)

      assert html =~ "#{host.displayname} is hosting #{streamer.displayname}"

      assert view
             |> has_element?("#hosted-banner")
    end

    test "redirects to hosted channel", %{conn: conn, streamer: streamer, host: host} do
      assert {:ok, conn} =
               live(conn, Routes.user_stream_path(conn, :index, host.username))
               |> follow_redirect(conn)

      assert html_response(conn, 200) =~ "#{host.displayname} is hosting #{streamer.displayname}"

      {:ok, view, _} = live(conn)

      assert view
             |> has_element?("#hosted-banner")
    end

    test "shows hosting message without redirect", %{conn: conn, streamer: streamer, host: host} do
      path = get(conn, Routes.user_stream_path(conn, :index, host.username), follow_host: "false")
      assert {:ok, view, html} = live(path)
      assert html =~ "#{host.displayname} is hosting #{streamer.displayname}"

      assert view
             |> has_element?("#hosting-banner")
    end

    test "does not redirect for host user", %{conn: conn, streamer: streamer} do
      %{conn: conn, user: host, channel: channel} =
        register_and_log_in_streamer_that_can_host(%{conn: conn})

      Glimesh.Repo.insert(%Glimesh.Streams.ChannelHosts{
        hosting_channel_id: channel.id,
        target_channel_id: streamer.channel.id,
        status: "hosting"
      })

      assert {:ok, view, html} = live(conn, Routes.user_stream_path(conn, :index, host.username))
      assert html =~ "#{host.displayname} is hosting #{streamer.displayname}"

      assert view
             |> has_element?("#hosting-banner")
    end

    test "does not redirect if the host user is live", %{
      conn: conn,
      host: host,
      streamer: streamer
    } do
      {:ok, _} = Glimesh.Streams.start_stream(host.channel)

      assert {:ok, view, html} = live(conn, Routes.user_stream_path(conn, :index, host.username))
      refute html =~ "#{host.displayname} is hosting #{streamer.displayname}"

      refute view
             |> has_element?("#hosting_banner")
    end

    test "does not redirect if the target user is no longer live", %{
      conn: conn,
      host: host,
      streamer: streamer
    } do
      {:ok, _} = Glimesh.Streams.end_stream(streamer.channel)

      assert {:ok, view, html} = live(conn, Routes.user_stream_path(conn, :index, host.username))
      refute html =~ "#{host.displayname} is hosting #{streamer.displayname}"

      refute view
             |> has_element?("#hosting_banner")
    end

    test "will not redirect the twitter bot to hosted channel", %{
      conn: conn,
      streamer: streamer,
      host: host
    } do
      conn =
        conn
        |> put_req_header("user-agent", "Twitterbot")

      {:ok, view, html} = live(conn, Routes.user_stream_path(conn, :index, host.username))
      assert html =~ "#{host.displayname} is hosting #{streamer.displayname}"
      refute conn.status == 302

      assert view
             |> has_element?("#hosting-banner")

      conn =
        conn
        |> put_req_header("user-agent", "test agent")

      assert {:ok, conn} =
               live(conn, Routes.user_stream_path(conn, :index, host.username))
               |> follow_redirect(conn)

      assert html_response(conn, 200) =~ "#{host.displayname} is hosting #{streamer.displayname}"
      {:ok, view, _} = live(conn)

      assert view
             |> has_element?("#hosted-banner")
    end
  end

  describe "Edit Stream Details Button" do
    setup do
      streamer = streamer_fixture()

      %{
        channel: streamer.channel,
        streamer: streamer
      }
    end

    test "is available to the channel owner", %{conn: conn, streamer: streamer} do
      streamer_conn = log_in_user(conn, streamer)

      {:ok, _, html} =
        live(streamer_conn, Routes.user_stream_path(streamer_conn, :index, streamer.username))

      assert html =~ "stream-title-edit"
    end

    test "is available to the moderators with edit permission", %{conn: conn, streamer: streamer} do
      %{moderator: moderator, channel_mod: _channel_mod} =
        moderator_fixture(streamer, streamer.channel, %{is_editor: true})

      moderator_conn = log_in_user(conn, moderator)

      {:ok, _, html} =
        live(moderator_conn, Routes.user_stream_path(moderator_conn, :index, streamer.username))

      assert html =~ "stream-title-edit"
    end

    test "is NOT available to the moderators without edit permission", %{
      conn: conn,
      streamer: streamer
    } do
      %{moderator: moderator, channel_mod: _channel_mod} =
        moderator_fixture(streamer, streamer.channel)

      moderator_conn = log_in_user(conn, moderator)

      {:ok, _, html} =
        live(moderator_conn, Routes.user_stream_path(moderator_conn, :index, streamer.username))

      refute html =~ "stream-title-edit"
    end

    test "is NOT available to regular users", %{conn: conn, streamer: streamer} do
      user = user_fixture()
      user_conn = log_in_user(conn, user)

      {:ok, _, html} =
        live(user_conn, Routes.user_stream_path(user_conn, :index, streamer.username))

      refute html =~ "stream-title-edit"
    end

    test "is available to the GCT members", %{conn: conn, streamer: streamer} do
      gct_user = gct_fixture()
      gct_conn = log_in_user(conn, gct_user)

      {:ok, _, html} =
        live(gct_conn, Routes.user_stream_path(gct_conn, :index, streamer.username))

      assert html =~ "stream-title-edit"
    end

    test "is available to the admin members", %{conn: conn, streamer: streamer} do
      admin_user = admin_fixture()
      admin_conn = log_in_user(conn, admin_user)

      {:ok, _, html} =
        live(admin_conn, Routes.user_stream_path(admin_conn, :index, streamer.username))

      assert html =~ "stream-title-edit"
    end
  end

  describe "Raid functionality" do
    setup do
      all_raidable_streamer = streamer_fixture(%{}, %{allow_raiding: true})

      follow_raidable_streamer =
        streamer_fixture(%{}, %{allow_raiding: true, only_followed_can_raid: true})

      not_raidable_streamer = streamer_fixture(%{}, %{allow_raiding: false})
      live_raider = streamer_fixture()
      live_followed_raider = streamer_fixture()
      Glimesh.AccountFollows.follow(live_followed_raider, follow_raidable_streamer)
      not_live_raider = streamer_fixture()
      not_live_streamer = streamer_fixture(%{}, %{allow_raiding: true})

      {:ok, _} = Glimesh.Streams.start_stream(all_raidable_streamer.channel)
      {:ok, _} = Glimesh.Streams.start_stream(follow_raidable_streamer.channel)
      {:ok, _} = Glimesh.Streams.start_stream(not_raidable_streamer.channel)
      {:ok, _} = Glimesh.Streams.start_stream(live_raider.channel)
      {:ok, _} = Glimesh.Streams.start_stream(live_followed_raider.channel)

      %{
        all_raidable_streamer: all_raidable_streamer,
        follow_raidable_streamer: follow_raidable_streamer,
        not_raidable_streamer: not_raidable_streamer,
        live_raider: live_raider,
        live_followed_raider: live_followed_raider,
        not_live_raider: not_live_raider,
        not_live_streamer: not_live_streamer
      }
    end

    test "raid button should show on allow all raids",
         %{
           conn: conn,
           all_raidable_streamer: all_raidable_streamer,
           not_raidable_streamer: not_raidable_streamer,
           live_raider: live_raider,
           not_live_raider: not_live_raider
         } do
      # live raider can raid streamer with all raids turned on
      live_raider_conn = log_in_user(conn, live_raider)

      {:ok, _, html} =
        live(
          live_raider_conn,
          Routes.user_stream_path(live_raider_conn, :index, all_raidable_streamer.username)
        )

      assert html =~ "raid-button"

      # live raider cannot raid streamer with all raids turned off
      {:ok, _, html} =
        live(
          live_raider_conn,
          Routes.user_stream_path(live_raider_conn, :index, not_raidable_streamer.username)
        )

      refute html =~ "raid-button"

      # non-live raider cannot raid anyone
      not_live_raider_conn = log_in_user(conn, not_live_raider)

      {:ok, _, html} =
        live(
          not_live_raider_conn,
          Routes.user_stream_path(live_raider_conn, :index, all_raidable_streamer.username)
        )

      refute html =~ "raid-button"

      {:ok, _, html} =
        live(
          not_live_raider_conn,
          Routes.user_stream_path(live_raider_conn, :index, not_raidable_streamer.username)
        )

      refute html =~ "raid-button"
    end

    test "raid button should show on allow raids from followed channels when appropriate",
         %{
           conn: conn,
           follow_raidable_streamer: follow_raidable_streamer,
           not_raidable_streamer: not_raidable_streamer,
           live_raider: live_not_followed_raider,
           live_followed_raider: live_followed_raider,
           not_live_raider: not_live_raider
         } do
      # live raider can raid streamer that follows the raider
      live_followed_raider_conn = log_in_user(conn, live_followed_raider)

      {:ok, _, html} =
        live(
          live_followed_raider_conn,
          Routes.user_stream_path(
            live_followed_raider_conn,
            :index,
            follow_raidable_streamer.username
          )
        )

      assert html =~ "raid-button"

      # live raider cannot raid streamer that doesn't follow the raider
      live_not_followed_raider_conn = log_in_user(conn, live_not_followed_raider)

      {:ok, _, html} =
        live(
          live_not_followed_raider_conn,
          Routes.user_stream_path(
            live_not_followed_raider_conn,
            :index,
            follow_raidable_streamer.username
          )
        )

      refute html =~ "raid-button"

      # non-live raider cannot raid anyone
      not_live_raider_conn = log_in_user(conn, not_live_raider)

      {:ok, _, html} =
        live(
          not_live_raider_conn,
          Routes.user_stream_path(not_live_raider_conn, :index, follow_raidable_streamer.username)
        )

      refute html =~ "raid-button"

      {:ok, _, html} =
        live(
          not_live_raider_conn,
          Routes.user_stream_path(not_live_raider_conn, :index, not_raidable_streamer.username)
        )

      refute html =~ "raid-button"
    end

    test "raid button should not show on non-live channels",
         %{
           conn: conn,
           not_live_streamer: not_live_streamer,
           live_raider: live_raider,
           not_live_raider: not_live_raider
         } do
      # live raider cannot raid streamer that isn't live
      live_raider_conn = log_in_user(conn, live_raider)

      {:ok, _, html} =
        live(
          live_raider_conn,
          Routes.user_stream_path(live_raider_conn, :index, not_live_streamer.username)
        )

      refute html =~ "raid-button"

      # non-live raider cannot raid anyone
      not_live_raider_conn = log_in_user(conn, not_live_raider)

      {:ok, _, html} =
        live(
          not_live_raider_conn,
          Routes.user_stream_path(not_live_raider_conn, :index, not_live_streamer.username)
        )

      refute html =~ "raid-button"
    end

    test "raid button should not show for raiders not logged in",
         %{conn: conn, all_raidable_streamer: all_raidable_streamer} do
      # cannot raid anyone if raider isn't logged in
      {:ok, _, html} =
        live(conn, Routes.user_stream_path(conn, :index, all_raidable_streamer.username))

      refute html =~ "raid-button"
    end

    test "raid button should not show for a streamer's own channel (cannot raid themselves)",
         %{conn: conn, all_raidable_streamer: all_raidable_streamer} do
      # cannot raid yourself
      streamer_conn = log_in_user(conn, all_raidable_streamer)

      {:ok, _, html} =
        live(
          streamer_conn,
          Routes.user_stream_path(streamer_conn, :index, all_raidable_streamer.username)
        )

      refute html =~ "raid-button"
    end

    test "viewers participating in raid are redirected to target channel and non-participants are not redirected",
         %{conn: conn, all_raidable_streamer: target_of_raid, live_raider: live_raider} do
      participating_viewer = user_fixture()

      participating_raid_user_viewer = %Glimesh.Streams.RaidUser{
        status: :pending,
        user_id: participating_viewer.id
      }

      second_participating_viewer = user_fixture()

      second_participating_raid_user_viewer = %Glimesh.Streams.RaidUser{
        status: :pending,
        user_id: second_participating_viewer.id
      }

      non_participating_viewer = user_fixture()
      raid_group_id = Ecto.UUID.generate()

      potential_raiding_viewers = [
        participating_raid_user_viewer,
        second_participating_raid_user_viewer
      ]

      participating_viewer_conn = log_in_user(conn, participating_viewer)
      second_participating_viewer_conn = log_in_user(conn, second_participating_viewer)
      non_participating_viewer_conn = log_in_user(conn, non_participating_viewer)

      {:ok, participating_viewer_view, _} =
        live(
          participating_viewer_conn,
          Routes.user_stream_path(participating_viewer_conn, :index, live_raider.username)
        )

      {:ok, second_participating_viewer_view, _} =
        live(
          second_participating_viewer_conn,
          Routes.user_stream_path(second_participating_viewer_conn, :index, live_raider.username)
        )

      {:ok, non_participating_viewer_view, _} =
        live(
          non_participating_viewer_conn,
          Routes.user_stream_path(non_participating_viewer_conn, :index, live_raider.username)
        )

      {:ok, non_logged_in_viewer_view, _} =
        live(conn, Routes.user_stream_path(conn, :index, live_raider.username))

      payload =
        {:raid,
         %{
           users: potential_raiding_viewers,
           target: target_of_raid.username,
           group_id: raid_group_id,
           action: "active"
         }}

      send(participating_viewer_view.pid, payload)
      send(second_participating_viewer_view.pid, payload)
      send(non_participating_viewer_view.pid, payload)
      send(non_logged_in_viewer_view.pid, payload)

      assert_redirect(
        participating_viewer_view,
        Routes.user_stream_path(participating_viewer_conn, :index, target_of_raid.username),
        5_000
      )

      assert_redirect(
        second_participating_viewer_view,
        Routes.user_stream_path(
          second_participating_viewer_conn,
          :index,
          target_of_raid.username
        ),
        5_000
      )

      refute_redirected(
        non_participating_viewer_view,
        Routes.user_stream_path(non_participating_viewer_conn, :index, target_of_raid.username)
      )

      refute_redirected(
        non_logged_in_viewer_view,
        Routes.user_stream_path(conn, :index, target_of_raid.username)
      )
    end

    test "viewers participating in raid are NOT redirected to target channel if the raid is cancelled",
         %{conn: conn, all_raidable_streamer: target_of_raid, live_raider: live_raider} do
      participating_viewer = user_fixture()

      participating_raid_user_viewer = %Glimesh.Streams.RaidUser{
        status: :pending,
        user_id: participating_viewer.id
      }

      second_participating_viewer = user_fixture()

      second_participating_raid_user_viewer = %Glimesh.Streams.RaidUser{
        status: :pending,
        user_id: second_participating_viewer.id
      }

      non_participating_viewer = user_fixture()
      raid_group_id = Ecto.UUID.generate()

      potential_raiding_viewers = [
        participating_raid_user_viewer,
        second_participating_raid_user_viewer
      ]

      participating_viewer_conn = log_in_user(conn, participating_viewer)
      second_participating_viewer_conn = log_in_user(conn, second_participating_viewer)
      non_participating_viewer_conn = log_in_user(conn, non_participating_viewer)

      {:ok, participating_viewer_view, _} =
        live(
          participating_viewer_conn,
          Routes.user_stream_path(participating_viewer_conn, :index, live_raider.username)
        )

      {:ok, second_participating_viewer_view, _} =
        live(
          second_participating_viewer_conn,
          Routes.user_stream_path(second_participating_viewer_conn, :index, live_raider.username)
        )

      {:ok, non_participating_viewer_view, _} =
        live(
          non_participating_viewer_conn,
          Routes.user_stream_path(non_participating_viewer_conn, :index, live_raider.username)
        )

      {:ok, non_logged_in_viewer_view, _} =
        live(conn, Routes.user_stream_path(conn, :index, live_raider.username))

      payload =
        {:raid,
         %{
           users: potential_raiding_viewers,
           target: target_of_raid.username,
           group_id: raid_group_id,
           action: "cancelled"
         }}

      send(participating_viewer_view.pid, payload)
      send(second_participating_viewer_view.pid, payload)
      send(non_participating_viewer_view.pid, payload)
      send(non_logged_in_viewer_view.pid, payload)

      refute_redirected(
        participating_viewer_view,
        Routes.user_stream_path(participating_viewer_conn, :index, target_of_raid.username)
      )

      assert render(participating_viewer_view) =~ "Streamer has cancelled pending raid."

      refute_redirected(
        second_participating_viewer_view,
        Routes.user_stream_path(second_participating_viewer_conn, :index, target_of_raid.username)
      )

      assert render(second_participating_viewer_view) =~ "Streamer has cancelled pending raid."

      refute_redirected(
        non_participating_viewer_view,
        Routes.user_stream_path(non_participating_viewer_conn, :index, target_of_raid.username)
      )

      assert render(non_participating_viewer_view) =~ "Streamer has cancelled pending raid."

      refute_redirected(
        non_logged_in_viewer_view,
        Routes.user_stream_path(conn, :index, target_of_raid.username)
      )

      assert render(non_logged_in_viewer_view) =~ "Streamer has cancelled pending raid."
    end

    test "viewers should get a message when a raid is about to happen",
         %{conn: conn, all_raidable_streamer: target_of_raid, live_raider: live_raider} do
      participating_viewer = user_fixture()
      second_participating_viewer = user_fixture()
      raid_group_id = Ecto.UUID.generate()

      participating_viewer_conn = log_in_user(conn, participating_viewer)
      second_participating_viewer_conn = log_in_user(conn, second_participating_viewer)

      {:ok, participating_viewer_view, _} =
        live(
          participating_viewer_conn,
          Routes.user_stream_path(participating_viewer_conn, :index, live_raider.username)
        )

      {:ok, second_participating_viewer_view, _} =
        live(
          second_participating_viewer_conn,
          Routes.user_stream_path(second_participating_viewer_conn, :index, live_raider.username)
        )

      {:ok, non_logged_in_viewer_view, _} =
        live(conn, Routes.user_stream_path(conn, :index, live_raider.username))

      time = NaiveDateTime.add(NaiveDateTime.utc_now(), 30, :second)

      raid_target = Glimesh.ChannelLookups.get_channel_for_username(target_of_raid.username)

      payload =
        {:raid, %{target: raid_target, group_id: raid_group_id, time: time, action: "pending"}}

      send(participating_viewer_view.pid, payload)
      send(second_participating_viewer_view.pid, payload)

      assert render(participating_viewer_view) =~ "raid-toast"
      assert render(second_participating_viewer_view) =~ "raid-toast"
      refute render(non_logged_in_viewer_view) =~ "raid-toast"
    end
  end
end
