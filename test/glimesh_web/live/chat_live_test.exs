defmodule GlimeshWeb.ChatLiveTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  import Phoenix.LiveViewTest

  alias Glimesh.Chat
  alias Glimesh.ChannelLookups

  describe "load chat" do
    setup :register_and_log_in_streamer
    @valid_chat_message %{message: "some message"}
    @bad_chat_message %{message: "bad word"}

    defp generate_message_for_channel(user, channel, message) do
      Chat.create_chat_message(user, channel, message)
    end

    defp generate_message_for_removal_test(bad_user, streamer, channel, message) do
      Chat.create_chat_message(streamer, channel, message)
      Chat.create_chat_message(bad_user, channel, @bad_chat_message)
    end

    defp generate_proper_conn(conn) do
      get(conn, Routes.homepage_path(conn, :index))
    end

    test "old chat messages display", %{conn: conn} do
      conn = generate_proper_conn(conn)
      user = conn.assigns.current_user
      channel = ChannelLookups.get_channel_for_user(user)
      generate_message_for_channel(user, channel, @valid_chat_message)

      {:ok, _view, html} = live(conn, Routes.user_stream_path(conn, :index, user.username))
      assert html =~ "some message"
    end
  end

  describe "mod actions" do
    test "short timeout removes chat message", %{conn: conn} do
      streamer = streamer_fixture()
      channel = ChannelLookups.get_channel_for_user(streamer)

      {:ok, chat_message} =
        generate_message_for_removal_test(user_fixture(), streamer, channel, @valid_chat_message)

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChatLive.Index,
          session: %{"user" => streamer, "channel_id" => channel.id}
        )

      target = "##{chat_message.id} > div.user-message-header > i.short-timeout"

      view
      |> element(target)
      |> render_click()

      refute render(view) =~ "bad word"
    end

    test "long timeout removes chat message", %{conn: conn} do
      streamer = streamer_fixture()
      channel = ChannelLookups.get_channel_for_user(streamer)

      {:ok, chat_message} =
        generate_message_for_removal_test(user_fixture(), streamer, channel, @valid_chat_message)

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChatLive.Index,
          session: %{"user" => streamer, "channel_id" => channel.id}
        )

      target = "##{chat_message.id} > div.user-message-header > i.long-timeout"

      view
      |> element(target)
      |> render_click()

      refute render(view) =~ "bad word"
    end

    test "ban removes chat message", %{conn: conn} do
      streamer = streamer_fixture()
      channel = ChannelLookups.get_channel_for_user(streamer)

      {:ok, chat_message} =
        generate_message_for_removal_test(user_fixture(), streamer, channel, @valid_chat_message)

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChatLive.Index,
          session: %{"user" => streamer, "channel_id" => channel.id}
        )

      target = "##{chat_message.id} > div.user-message-header > i.ban"

      view
      |> element(target)
      |> render_click()

      refute render(view) =~ "bad word"
    end
  end

  describe "chat preferences" do
    test "toggle timestamps button toggles them", %{conn: conn} do
      user = streamer_fixture()
      channel = ChannelLookups.get_channel_for_user(user)

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChatLive.Index,
          session: %{"user" => user, "channel_id" => channel.id}
        )

      assert render(view) =~ "Enable Timestamps"

      view
      |> element("#toggle-timestamps")
      |> render_click()

      assert render(view) =~ "Disable Timestamps"
    end
  end
end
