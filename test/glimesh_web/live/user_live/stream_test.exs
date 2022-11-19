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

  describe "Opt-in to Homepage Notification" do
    test "is only displayed to the channel owner", %{conn: conn} do
      streamer = streamer_fixture(%{}, %{prompt_for_homepage: :prompt})
      streamer_conn = log_in_user(conn, streamer)
      viewer = user_fixture()
      viewer_conn = log_in_user(conn, viewer)

      {:ok, _, html} =
        live(streamer_conn, Routes.user_stream_path(streamer_conn, :index, streamer.username))

      assert html =~ "homepage-prompt-banner"

      {:ok, _, html} =
        live(viewer_conn, Routes.user_stream_path(viewer_conn, :index, streamer.username))

      refute html =~ "homepage-prompt-banner"
    end

    test "is only displayed if the channel owner hasn't opted in", %{conn: conn} do
      streamer = streamer_fixture(%{}, %{show_on_homepage: true, prompt_for_homepage: :prompt})
      streamer_conn = log_in_user(conn, streamer)

      {:ok, _, html} =
        live(streamer_conn, Routes.user_stream_path(streamer_conn, :index, streamer.username))

      refute html =~ "homepage-prompt-banner"
    end

    test "is only displayed if the prompt flag is set", %{conn: conn} do
      streamer_one = streamer_fixture(%{}, %{prompt_for_homepage: :ignore})
      streamer_one_conn = log_in_user(conn, streamer_one)
      streamer_two = streamer_fixture(%{}, %{prompt_for_homepage: :ineligible})
      streamer_two_conn = log_in_user(conn, streamer_two)

      {:ok, _, html_one} =
        live(
          streamer_one_conn,
          Routes.user_stream_path(streamer_one_conn, :index, streamer_one.username)
        )

      refute html_one =~ "homepage-prompt-banner"

      {:ok, _, html_two} =
        live(
          streamer_two_conn,
          Routes.user_stream_path(streamer_two_conn, :index, streamer_two.username)
        )

      refute html_two =~ "homepage-prompt-banner"
    end

    test "can be dismissed by the channel owner", %{conn: conn} do
      streamer = streamer_fixture(%{}, %{prompt_for_homepage: :prompt})
      streamer_conn = log_in_user(conn, streamer)

      {:ok, view, html} =
        live(streamer_conn, Routes.user_stream_path(streamer_conn, :index, streamer.username))

      assert html =~ "homepage-prompt-banner"

      refute render_click(view, "dismiss_homepage_prompt") =~ "homepage-prompt-banner"

      updated_channel = Glimesh.Repo.get(Glimesh.Streams.Channel, streamer.channel.id)
      assert updated_channel.prompt_for_homepage == :ignore
    end
  end
end
