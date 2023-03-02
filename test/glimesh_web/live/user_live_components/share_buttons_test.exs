defmodule GlimeshWeb.UserLive.Components.ShareButtonsTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glimesh.AccountsFixtures

  @component GlimeshWeb.UserLive.Components.ShareButtons

  defp create_channel(_) do
    streamer = streamer_fixture()

    %{
      streamer: streamer
    }
  end

  describe "share buttons" do
    setup :create_channel

    test "render correctly", %{conn: conn, streamer: streamer} do
      {:ok, _} =
        Glimesh.Streams.update_channel(streamer, streamer.channel, %{share_text: "this is a test"})

      {:ok, view, _html} =
        live_isolated(conn, @component,
          session: %{
            "streamer_username" => streamer.username,
            "streamer_displayname" => streamer.displayname,
            "share_text" => streamer.channel.share_text
          }
        )

      html = render_click(view, :show_modal)

      assert html =~ "shareModal"
      assert html =~ streamer.channel.share_text
      assert html =~ streamer.displayname
    end
  end
end
