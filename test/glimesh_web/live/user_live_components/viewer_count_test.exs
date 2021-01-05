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
      {:ok, _, html} = live_isolated(conn, @component, session: %{"channel_id" => channel.id})

      assert html =~ "0 Viewers"
    end

    test "shows one viewer by loading a stream", %{conn: conn, channel: channel} do
      {:ok, view, _} = live_isolated(conn, @component, session: %{"channel_id" => channel.id})
      streamer = Glimesh.Accounts.get_user!(channel.user_id)

      assert render(view) =~ "0 Viewers"

      {:ok, _, _} = live(conn, Routes.user_stream_path(conn, :index, streamer.username))

      # Due to a bug with LiveView in testing, the above live statement triggers two viewers, one with CSRF and one without
      assert render(view) =~ "1 Viewers"
    end
  end
end
