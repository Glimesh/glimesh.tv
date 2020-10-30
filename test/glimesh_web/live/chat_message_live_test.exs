defmodule GlimeshWeb.ChatMessageLiveTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures

  alias Glimesh.Chat

  @create_attrs %{message: "some message"}
  @update_attrs %{message: "some updated message"}
  @invalid_attrs %{message: nil}

  defp fixture(:chat_message) do
    {:ok, chat_message} = Chat.create_chat_message(user_fixture(), user_fixture(), @create_attrs)
    chat_message
  end

  defp setup_streamer do
    user_fixture()
  end

  defp create_chat_message(_) do
    chat_message = fixture(:chat_message)
    %{chat_message: chat_message}
  end

  describe "Index" do
    setup [:create_chat_message]
    #
    #    test "lists all chat_messages", %{conn: conn, chat_message: chat_message} do
    #      streamer = setup_streamer()
    #      {:ok, index_live, html} = live(conn, Routes.user_stream_path(conn, :index, streamer.username))
    #
    #      assert html =~ "Welcome to chat! Follow the rules."
    #      assert html =~ chat_message.message
    #    end
    ##
    #    test "saves new chat_message", %{conn: conn} do
    #      {:ok, index_live, _html} = live(conn, Routes.chat_message_index_path(conn, :index))
    #
    #      assert index_live |> element("a", "New Chat message") |> render_click() =~
    #               "New Chat message"
    #
    #      assert_patch(index_live, Routes.chat_message_index_path(conn, :new))
    #
    #      assert index_live
    #             |> form("#chat_message-form", chat_message: @invalid_attrs)
    #             |> render_change() =~ "can&apos;t be blank"
    #
    #      {:ok, _, html} =
    #        index_live
    #        |> form("#chat_message-form", chat_message: @create_attrs)
    #        |> render_submit()
    #        |> follow_redirect(conn, Routes.chat_message_index_path(conn, :index))
    #
    #      assert html =~ "Chat message created successfully"
    #      assert html =~ "some message"
    #    end
    #
    #    test "updates chat_message in listing", %{conn: conn, chat_message: chat_message} do
    #      {:ok, index_live, _html} = live(conn, Routes.chat_message_index_path(conn, :index))
    #
    #      assert index_live |> element("#chat_message-#{chat_message.id} a", "Edit") |> render_click() =~
    #               "Edit Chat message"
    #
    #      assert_patch(index_live, Routes.chat_message_index_path(conn, :edit, chat_message))
    #
    #      assert index_live
    #             |> form("#chat_message-form", chat_message: @invalid_attrs)
    #             |> render_change() =~ "can&apos;t be blank"
    #
    #      {:ok, _, html} =
    #        index_live
    #        |> form("#chat_message-form", chat_message: @update_attrs)
    #        |> render_submit()
    #        |> follow_redirect(conn, Routes.chat_message_index_path(conn, :index))
    #
    #      assert html =~ "Chat message updated successfully"
    #      assert html =~ "some updated message"
    #    end
    #
    #    test "deletes chat_message in listing", %{conn: conn, chat_message: chat_message} do
    #      {:ok, index_live, _html} = live(conn, Routes.chat_message_index_path(conn, :index))
    #
    #      assert index_live |> element("#chat_message-#{chat_message.id} a", "Delete") |> render_click()
    #      refute has_element?(index_live, "#chat_message-#{chat_message.id}")
    #    end
  end

  #  describe "Show" do
  #    setup [:create_chat_message]
  #
  #    test "displays chat_message", %{conn: conn, chat_message: chat_message} do
  #      {:ok, _show_live, html} = live(conn, Routes.chat_message_show_path(conn, :show, chat_message))
  #
  #      assert html =~ "Show Chat message"
  #      assert html =~ chat_message.message
  #    end
  #
  #    test "updates chat_message within modal", %{conn: conn, chat_message: chat_message} do
  #      {:ok, show_live, _html} = live(conn, Routes.chat_message_show_path(conn, :show, chat_message))
  #
  #      assert show_live |> element("a", "Edit") |> render_click() =~
  #               "Edit Chat message"
  #
  #      assert_patch(show_live, Routes.chat_message_show_path(conn, :edit, chat_message))
  #
  #      assert show_live
  #             |> form("#chat_message-form", chat_message: @invalid_attrs)
  #             |> render_change() =~ "can&apos;t be blank"
  #
  #      {:ok, _, html} =
  #        show_live
  #        |> form("#chat_message-form", chat_message: @update_attrs)
  #        |> render_submit()
  #        |> follow_redirect(conn, Routes.chat_message_show_path(conn, :show, chat_message))
  #
  #      assert html =~ "Chat message updated successfully"
  #      assert html =~ "some updated message"
  #    end
  #  end
end
