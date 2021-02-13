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

      assert render(view) =~ "some-de-server"
      assert render(view) =~ "https://some-de-server/janus"
    end
  end
end
