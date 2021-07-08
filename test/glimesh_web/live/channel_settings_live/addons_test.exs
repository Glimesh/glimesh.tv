defmodule GlimeshWeb.ChannelSettingsLive.AddonsTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest

  describe "Channel Addons" do
    setup [:register_and_log_in_streamer]

    test "can set streamloots url", %{conn: conn, user: user, channel: channel} do
      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.Addons, session: %{"user" => user})

      form = view |> element("#addons")

      assert render_submit(form, %{
               "channel" => %{"streamloots_url" => "https://www.streamloots.com/ferret"}
             }) =~
               "Updated addons."

      assert Glimesh.ChannelLookups.get_channel!(channel.id).streamloots_url ==
               "https://www.streamloots.com/ferret"
    end

    test "can clear streamloots url", %{conn: conn, user: user, channel: channel} do
      {:ok, _} =
        Glimesh.Streams.update_addons(user, channel, %{
          "streamloots_url" => "https://www.streamloots.com/ferret"
        })

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.Addons, session: %{"user" => user})

      form = view |> element("#addons")

      assert render_submit(form, %{"channel" => %{"streamloots_url" => ""}}) =~
               "Updated addons."

      assert is_nil(Glimesh.ChannelLookups.get_channel!(channel.id).streamloots_url)
    end
  end
end
