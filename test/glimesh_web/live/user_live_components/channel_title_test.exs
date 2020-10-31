defmodule GlimeshWeb.UserLive.Components.ChannelTitleTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glimesh.AccountsFixtures

  @component GlimeshWeb.UserLive.Components.ChannelTitle

  defp create_channel(_) do
    channel = channel_fixture()
    streamer = Glimesh.Accounts.get_user!(channel.user_id)

    %{
      channel: channel,
      streamer: streamer
    }
  end

  describe "channel title unauthed user" do
    setup :create_channel

    test "shows the channels title", %{conn: conn, channel: channel} do
      {:ok, _, html} =
        live_isolated(conn, @component, session: %{"user" => nil, "channel_id" => channel.id})

      assert html =~ "Live Stream!"
      assert String.contains?(html, "Live!") == false
    end

    test "shows the channel when its online online", %{conn: conn, channel: channel} do
      {:ok, view, html} =
        live_isolated(conn, @component, session: %{"user" => nil, "channel_id" => channel.id})

      assert html =~ "Live Stream!"
      assert String.contains?(html, "Live!") == false

      {:ok, _} = Glimesh.Streams.start_stream(channel)
      assert String.contains?(render(view), "Live!") == true
    end
  end

  describe "channel authed user" do
    setup [:register_and_log_in_user, :create_channel]

    test "shows the channels title", %{conn: conn, user: user, channel: channel} do
      {:ok, _, html} =
        live_isolated(conn, @component, session: %{"user" => user, "channel_id" => channel.id})

      assert html =~ "Live Stream!"
      refute String.contains?(html, "Live!")
    end

    test "shows the channel when its online online", %{conn: conn, user: user, channel: channel} do
      {:ok, view, html} =
        live_isolated(conn, @component, session: %{"user" => user, "channel_id" => channel.id})

      assert html =~ "Live Stream!"
      refute String.contains?(html, "Live!")

      {:ok, _} = Glimesh.Streams.start_stream(channel)
      assert String.contains?(render(view), "Live!")
    end

    test "random user cannot edit", %{conn: conn, user: user, channel: channel} do
      {:ok, _, html} =
        live_isolated(conn, @component, session: %{"user" => user, "channel_id" => channel.id})

      refute String.contains?(html, "toggle-edit")
    end
  end

  describe "channel streamer user" do
    setup [:register_and_log_in_user, :create_channel]

    test "streamer can edit title", %{conn: conn, streamer: streamer, channel: channel} do
      {:ok, view, html} =
        live_isolated(conn, @component, session: %{"user" => streamer, "channel_id" => channel.id})

      assert String.contains?(html, "toggle-edit")

      assert render_submit(view, :save, %{
               "channel" => %{
                 "title" => "Foobar"
               }
             }) =~ "Foobar"
    end
  end
end
