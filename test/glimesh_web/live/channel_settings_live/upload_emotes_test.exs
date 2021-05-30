defmodule GlimeshWeb.ChannelSettingsLive.UploadEmotesTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glimesh.AccountsFixtures

  @glimchef %{
    last_modified: 1_594_171_879_000,
    name: "glimchef.svg",
    content: File.read!("test/assets/glimchef.svg"),
    size: 19_056,
    type: "image/svg+xml"
  }

  describe "Channel Emotes Uploading" do
    setup [:register_and_log_in_streamer]

    test "can set channel prefix", %{conn: conn, user: user} do
      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.UploadEmotes,
          session: %{"user" => user}
        )

      form = view |> element("#emote_settings")

      assert render_submit(form, %{"channel" => %{"emote_prefix" => "testg"}}) =~
               "Updated channel emote settings."
    end

    test "can upload emotes", %{conn: conn, user: user, channel: channel} do
      {:ok, channel} =
        Glimesh.Streams.update_emote_settings(user, channel, %{
          emote_prefix: "testg"
        })

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.UploadEmotes,
          session: %{"user" => user}
        )

      avatar =
        file_input(view, "#emote_upload", :emote, [
          @glimchef
        ])

      assert render_upload(avatar, "glimchef.svg") =~ "glimchef"

      render_submit(
        element(view, "form#emote_upload"),
        Enum.into(avatar.entries, %{}, fn x ->
          {x["ref"], "glimchef"}
        end)
      )

      flash = assert_redirected(view, "/users/settings/emotes")

      assert flash["info"] ==
               "Successfully uploaded emotes, pending review by the Glimesh Community Team"

      emote = Glimesh.Emotes.get_emote_by_emote("testgglimchef")
      assert emote.channel_id == channel.id
      assert is_nil(emote.approved_at)
    end
  end
end
