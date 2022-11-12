defmodule GlimeshWeb.UserLive.Components.ViewerCountTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glimesh.AccountsFixtures

  @component GlimeshWeb.UserLive.Components.ViewerCount

  defp create_channel(_) do
    %{channel: channel} = streamer_fixture()
    %{channel: channel}
  end

  describe "viewer counts" do
    setup :create_channel

    test "shows no viewer without loading stream", %{conn: conn, channel: channel} do
      {:ok, _, html} =
        live_isolated(conn, @component,
          session: %{"channel_id" => channel.id, "viewer_count_state" => :visible}
        )

      assert html =~ "0 Viewers"
    end

    test "shows one viewer by loading a stream", %{conn: conn, channel: channel} do
      {:ok, view, _} =
        live_isolated(conn, @component,
          session: %{"channel_id" => channel.id, "viewer_count_state" => :visible}
        )

      streamer = Glimesh.Accounts.get_user!(channel.user_id)

      assert render(view) =~ "0 Viewers"

      Glimesh.Janus.create_edge_route(%{
        hostname: "some-server",
        url: "https://some-server/janus",
        priority: 1.0,
        available: true,
        country_codes: []
      })

      {:ok, stream_view, _} = live(conn, Routes.user_stream_path(conn, :index, streamer.username))
      # Poke janus to ensure we show up as a viewer
      assert render(stream_view) =~ "1 Viewers"

      assert render(view) =~ "1 Viewers"
    end

    test "can hide the viewer count", %{conn: conn, channel: channel} do
      {:ok, view, _} =
        live_isolated(conn, @component,
          session: %{"channel_id" => channel.id, "viewer_count_state" => :visible}
        )

      assert view |> element("button") |> render_click() =~ "far fa-eye-slash"
    end

    test "is minimized if preference set", %{conn: conn, channel: channel} do
      {:ok, view, _} =
        live_isolated(conn, @component,
          session: %{"channel_id" => channel.id, "viewer_count_state" => :minimize}
        )

      assert render(view) =~ "far fa-eye-slash"
    end

    test "can be maximized if minimized", %{conn: conn, channel: channel} do
      {:ok, view, _} =
        live_isolated(conn, @component,
          session: %{"channel_id" => channel.id, "viewer_count_state" => :minimize}
        )

      assert view |> element("button") |> render_click() =~ "Viewers"
    end

    test "is hidden if preference set", %{conn: conn, channel: channel} do
      {:ok, view, _} =
        live_isolated(conn, @component,
          session: %{"channel_id" => channel.id, "viewer_count_state" => :hidden}
        )

      refute render(view) =~ "Viewers"
    end
  end
end
