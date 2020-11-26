defmodule GlimeshWeb.ChatLiveTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  import Phoenix.LiveViewTest

  alias Glimesh.Chat
  alias Glimesh.Streams

  describe "load chat" do
    setup :register_and_log_in_streamer
    @valid_chat_message %{message: "some message"}

    defp generate_message_for_channel(user, channel, message) do
      Chat.create_chat_message(user, channel, message)
    end

    defp generate_proper_conn(conn) do
      get(conn, Routes.homepage_path(conn, :index))
    end

    test "old chat messages display", %{conn: conn} do
      conn = generate_proper_conn(conn)
      user = conn.assigns.current_user
      channel = Streams.get_channel_for_user(user)
      generate_message_for_channel(user, channel, @valid_chat_message)

      {:ok, _view, html} = live(conn, Routes.user_stream_path(conn, :index, user.username))
      assert html =~ "some message"
    end
  end

  describe "mod actions" do

    test "short timneout removes chat message", %{conn: conn} do
      user = streamer_fixture()
      channel = Streams.get_channel_for_user(user)
      generate_message_for_channel(user, channel, @valid_chat_message)

      {:ok, view, _html} = live_isolated(conn, GlimeshWeb.ChatLive.Index, session: %{"user" => user, "channel_id" => channel.id})

      view
      |> element("#short-timeout")
      |> render_click()

      refute render(view) =~ "some message"

    end

    test "long timneout removes chat message", %{conn: conn} do
      user = streamer_fixture()
      channel = Streams.get_channel_for_user(user)
      generate_message_for_channel(user, channel, @valid_chat_message)

      {:ok, view, _html} = live_isolated(conn, GlimeshWeb.ChatLive.Index, session: %{"user" => user, "channel_id" => channel.id})

      view
      |> element("#long-timeout")
      |> render_click()

      refute render(view) =~ "some message"

    end

    test "ban removes chat message", %{conn: conn} do
      user = streamer_fixture()
      channel = Streams.get_channel_for_user(user)
      generate_message_for_channel(user, channel, @valid_chat_message)

      {:ok, view, _html} = live_isolated(conn, GlimeshWeb.ChatLive.Index, session: %{"user" => user, "channel_id" => channel.id})

      view
      |> element("#ban")
      |> render_click()

      refute render(view) =~ "some message"

    end
  end

  describe "chat preferences" do

    test "toggle timestamps button toggles them", %{conn: conn} do
      user = streamer_fixture()
      channel = Streams.get_channel_for_user(user)
      {:ok, chat_message} = generate_message_for_channel(user, channel, @valid_chat_message)

      {:ok, view, _html} = live_isolated(conn, GlimeshWeb.ChatLive.Index, session: %{"user" => user, "channel_id" => channel.id})

      refute render(view) =~ Time.to_string(NaiveDateTime.to_time(chat_message.inserted_at))

      view
      |> element("#toggle-timestamps")
      |> render_click()

      assert render(view) =~ Time.to_string(NaiveDateTime.to_time(chat_message.inserted_at))

    end
  end

end
