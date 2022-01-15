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

    test "lost_packets doesnt crash", %{conn: conn, streamer: streamer} do
      {:ok, view, _} = live(conn, Routes.user_stream_path(conn, :index, streamer.username))

      params = %{
        "uplink" => "doesnt matter",
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
        "uplink" => "doesnt matter",
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
        "uplink" => "doesnt matter",
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
  end
end
