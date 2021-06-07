defmodule GlimeshWeb.GctLive.ReviewEmotesTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glimesh.AccountsFixtures

  @glimchef %{
    emote: "glimchef",
    animated: false,
    static_file: %Plug.Upload{
      content_type: "image/svg+xml",
      path: "test/assets/glimchef.svg",
      filename: "glimchef.svg"
    }
  }

  describe "Emote Review" do
    setup [:register_and_log_in_gct_user, :create_channel]

    test "can see and approve pending emotes", %{
      conn: conn,
      user: user,
      streamer: streamer,
      channel: channel
    } do
      {:ok, _} = Glimesh.Emotes.create_channel_emote(streamer, channel, @glimchef)

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.GctLive.ReviewEmotes, session: %{"user" => user})

      assert render(view) =~ "testgglimchef"
    end

    test "can see and reject pending emotes", %{
      conn: conn,
      user: user,
      streamer: streamer,
      channel: channel
    } do
      {:ok, _} = Glimesh.Emotes.create_channel_emote(streamer, channel, @glimchef)

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.GctLive.ReviewEmotes, session: %{"user" => user})

      assert render(view) =~ "testgglimchef"

      assert view
             |> element("button", "Reject")
             |> render_click() =~ "Rejected testgglimchef"
    end
  end

  defp create_channel(_) do
    streamer = streamer_fixture()

    {:ok, channel} =
      Glimesh.Streams.update_emote_settings(streamer, streamer.channel, %{
        emote_prefix: "testg"
      })

    %{streamer: streamer, channel: channel}
  end
end
