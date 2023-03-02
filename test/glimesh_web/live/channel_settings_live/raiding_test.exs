defmodule GlimeshWeb.ChannelSettingsLive.RaidingTest do
  use GlimeshWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Glimesh.AccountsFixtures

  describe "Allow Raiding Settings" do
    setup :register_and_log_in_streamer

    test "can set allow raiding", %{conn: conn, user: user, channel: channel} do
      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.Raiding, session: %{"user" => user})

      form = view |> element(".form_allow_raiding")

      assert render_change(form, %{
               "channel" => %{"allow_raiding" => "true"}
             }) =~
               "Saved Raiding Preference."

      assert Glimesh.ChannelLookups.get_channel!(channel.id).allow_raiding == true
    end

    test "can set disallow raiding", %{conn: conn, user: user, channel: channel} do
      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.Raiding, session: %{"user" => user})

      form = view |> element(".form_allow_raiding")

      assert render_change(form, %{
               "channel" => %{"allow_raiding" => "false"}
             }) =~
               "Saved Raiding Preference."

      assert Glimesh.ChannelLookups.get_channel!(channel.id).allow_raiding == false
    end
  end

  describe "Only Allow Raids From Followed Settings" do
    setup :register_and_log_in_streamer_that_can_be_raided

    test "can set allow raids only from followed channels", %{
      conn: conn,
      user: user,
      channel: channel
    } do
      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.Raiding, session: %{"user" => user})

      form = view |> element(".form_only_allow_followed")

      assert render_change(form, %{
               "channel" => %{"only_followed_can_raid" => "true"}
             }) =~
               "Saved Raiding Preference."

      assert Glimesh.ChannelLookups.get_channel!(channel.id).only_followed_can_raid == true
    end

    test "can set allow all raids", %{conn: conn, user: user, channel: channel} do
      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.Raiding, session: %{"user" => user})

      form = view |> element(".form_only_allow_followed")

      assert render_change(form, %{
               "channel" => %{"only_followed_can_raid" => "false"}
             }) =~
               "Saved Raiding Preference."

      assert Glimesh.ChannelLookups.get_channel!(channel.id).only_followed_can_raid == false
    end
  end

  describe "Can set raiding message" do
    setup :register_and_log_in_streamer

    test "can update message", %{conn: conn, user: user, channel: channel} do
      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.Raiding, session: %{"user" => user})

      form = view |> element(".form_raid_message")

      assert render_submit(form, %{
               "channel" => %{
                 "raid_message" => "this is a test raid message for {streamer} and {count}"
               }
             }) =~
               "Saved Raiding Preference."

      assert Glimesh.ChannelLookups.get_channel!(channel.id).raid_message ===
               "this is a test raid message for {streamer} and {count}"
    end
  end

  describe "can ban channels from raiding" do
    setup :register_and_log_in_streamer

    test "can find a channel to ban", %{conn: conn, user: user} do
      streamer_one = streamer_fixture()
      streamer_two = streamer_fixture()
      user_one = user_fixture()

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.Raiding, session: %{"user" => user})

      view
      |> element(".form_ban_channel")
      |> render_change(%{"suggest" => %{"ban_channel" => "user"}})

      assert has_element?(view, "#channel-lookup-#{streamer_one.id}")
      assert has_element?(view, "#channel-lookup-#{streamer_two.id}")
      refute has_element?(view, "#channel-lookup-#{user_one.id}")
    end

    test "can ban a channel", %{conn: conn} do
      streamer_one = streamer_fixture()
      {:ok, view, _html} = live(conn, Routes.user_settings_path(conn, :raiding))

      render_hook(view, :ban_channel_selection_made, %{
        user_id: streamer_one.id,
        username: streamer_one.displayname,
        channel_id: streamer_one.channel.id
      })

      assert {:ok, conn} =
               view
               |> element("#ban-channel-button")
               |> render_click()
               |> follow_redirect(conn, Routes.user_settings_path(conn, :raiding))

      assert html_response(conn, 200) =~ "Channel banned from raiding"

      {:ok, redirected_view, _html} = live(conn)
      assert has_element?(redirected_view, "#banned-row-#{streamer_one.channel.id}")
    end

    test "can ban a channel without using the picker", %{conn: conn} do
      streamer_one = streamer_fixture()
      {:ok, view, _html} = live(conn, Routes.user_settings_path(conn, :raiding))

      assert {:ok, conn} =
               view
               |> element("#ban-channel-button")
               |> render_click(%{"name" => streamer_one.displayname, "selected" => ""})
               |> follow_redirect(conn, Routes.user_settings_path(conn, :raiding))

      assert html_response(conn, 200) =~ "Channel banned from raiding"

      {:ok, redirected_view, _html} = live(conn)
      assert has_element?(redirected_view, "#banned-row-#{streamer_one.channel.id}")
    end
  end
end
