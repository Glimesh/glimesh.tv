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
      get(conn, ~p"/")
    end

    test "old chat messages display", %{conn: conn} do
      conn = generate_proper_conn(conn)
      user = conn.assigns.current_user
      channel = ChannelLookups.get_channel_for_user(user)
      generate_message_for_channel(user, channel, @valid_chat_message)

      {:ok, _view, html} = live(conn, ~p"/#{user.username}")
      assert html =~ "some message"
    end
  end

  describe "normal chat stuff" do
    setup do
      streamer = streamer_fixture()

      %{
        streamer: streamer,
        channel: streamer.channel,
        user: user_fixture()
      }
    end

    test "can post a chat message", %{conn: conn, channel: channel, user: user} do
      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChatLive.Index,
          session: %{"user" => user, "channel_id" => channel.id}
        )

      view
      |> element("form")
      |> render_submit(%{"chat_message" => %{message: "Hello world"}})

      assert render(view) =~ "Hello world"
    end
  end

  describe "chat preventions" do
    setup do
      streamer = streamer_fixture()

      %{
        streamer: streamer,
        channel: streamer.channel,
        user: user_fixture()
      }
    end

    test "cannot post a chat message if you have been channel banned", %{
      conn: conn,
      streamer: streamer,
      channel: channel,
      user: user
    } do
      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChatLive.Index,
          session: %{"user" => user, "channel_id" => channel.id}
        )

      # We want to test an async platform ban where the user's session is not rejected
      {:ok, _} = Glimesh.Chat.ban_user(streamer, channel, user)

      assert view
             |> element("form")
             |> render_submit(%{"chat_message" => %{message: "Hello world"}}) =~
               "You are permanently banned from this channel"

      refute render(view) =~ "Hello world"
    end

    test "cannot post a chat message if you have been platform banned", %{
      conn: conn,
      channel: channel,
      user: user
    } do
      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChatLive.Index,
          session: %{"user" => user, "channel_id" => channel.id}
        )

      # We want to test an async platform ban where the user's session is not rejected
      {:ok, _} = Glimesh.Accounts.ban_user(admin_fixture(), user, "Noperino")

      assert view
             |> element("form")
             |> render_submit(%{"chat_message" => %{message: "Hello world"}}) =~
               "You are banned from Glimesh"

      refute render(view) =~ "Hello world"
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

      target = "#chat-message-#{chat_message.id} > div.user-message-header > i.short-timeout"

      view
      |> element(target)
      |> render_click()

      # Render a new view to test to make sure the message is gone
      {:ok, new_view, _html} =
        live_isolated(conn, GlimeshWeb.ChatLive.Index,
          session: %{"user" => streamer, "channel_id" => channel.id}
        )

      refute render(new_view) =~ chat_message.message
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

      target = "#chat-message-#{chat_message.id} > div.user-message-header > i.long-timeout"

      view
      |> element(target)
      |> render_click()

      # Render a new view to test to make sure the message is gone
      {:ok, new_view, _html} =
        live_isolated(conn, GlimeshWeb.ChatLive.Index,
          session: %{"user" => streamer, "channel_id" => channel.id}
        )

      refute render(new_view) =~ chat_message.message
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

      target = "#chat-message-#{chat_message.id} > div.user-message-header > i.ban"

      view
      |> element(target)
      |> render_click()

      # Render a new view to test to make sure the message is gone
      {:ok, new_view, _html} =
        live_isolated(conn, GlimeshWeb.ChatLive.Index,
          session: %{"user" => streamer, "channel_id" => channel.id}
        )

      refute render(new_view) =~ chat_message.message
    end

    test "delete message button deletes message", %{conn: conn} do
      streamer = streamer_fixture()
      channel = ChannelLookups.get_channel_for_user(streamer)

      {:ok, chat_message} =
        generate_message_for_removal_test(user_fixture(), streamer, channel, @valid_chat_message)

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChatLive.Index,
          session: %{"user" => streamer, "channel_id" => channel.id}
        )

      target = "#chat-message-#{chat_message.id} > div.user-message-header > i.delete-message"

      view
      |> element(target)
      |> render_click()

      # Render a new view to test to make sure the message is gone
      {:ok, new_view, _html} =
        live_isolated(conn, GlimeshWeb.ChatLive.Index,
          session: %{"user" => streamer, "channel_id" => channel.id}
        )

      refute render(new_view) =~ chat_message.message
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

      assert render(view) =~ "Show Timestamps"

      view
      |> element("#toggle-timestamps")
      |> render_click()

      assert render(view) =~ "Hide Timestamps"
    end

    test "toggle mod icons button toggles mod icons", %{conn: conn} do
      user = streamer_fixture()
      channel = ChannelLookups.get_channel_for_user(user)

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChatLive.Index,
          session: %{"user" => user, "channel_id" => channel.id}
        )

      assert render(view) =~ "Hide Mod Icons"

      view
      |> element("#toggle-mod-icons")
      |> render_click()

      assert render(view) =~ "Show Mod Icons"
    end
  end
end
