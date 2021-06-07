defmodule GlimeshWeb.ChannelSettingsLive.ChannelEmotesTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Glimesh.Emotes.Emote

  @emote_attrs %{
    emote: "myemote",
    animated: false,
    static_file: %Plug.Upload{
      content_type: "image/svg+xml",
      path: "test/assets/glimchef.svg",
      filename: "glimchef.svg"
    }
  }

  describe "Channel Emotes Management" do
    setup [:register_and_log_in_streamer]

    test "can view approved channel emotes", %{conn: conn, user: user, channel: channel} do
      {:ok, channel} =
        Glimesh.Streams.update_emote_settings(user, channel, %{
          emote_prefix: "mycha"
        })

      assert {:ok, %Emote{} = approved_emote} =
               Glimesh.Emotes.create_channel_emote(
                 user,
                 channel,
                 Map.merge(@emote_attrs, %{
                   approved_at: NaiveDateTime.utc_now()
                 })
               )

      {:ok, _view, html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.ChannelEmotes,
          session: %{"user" => user}
        )

      assert html =~ "Channel Emotes"
      assert html =~ ":#{approved_emote.emote}:"
    end

    test "can delete approved or pending emotes", %{conn: conn, user: user, channel: channel} do
      {:ok, channel} =
        Glimesh.Streams.update_emote_settings(user, channel, %{
          emote_prefix: "mycha"
        })

      assert {:ok, %Emote{}} =
               Glimesh.Emotes.create_channel_emote(
                 user,
                 channel,
                 Map.merge(@emote_attrs, %{
                   approved_at: NaiveDateTime.utc_now()
                 })
               )

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.ChannelEmotes,
          session: %{"user" => user}
        )

      element(view, "button") |> render_click()

      flash = assert_redirected(view, "/users/settings/emotes")

      assert flash["emote_info"] ==
               "Deleted mychamyemote"
    end
  end
end
