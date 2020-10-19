defmodule GlimeshWeb.ChannelModeratorControllerTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  alias Glimesh.Streams

  setup :register_and_log_in_streamer

  @create_attrs %{
    can_ban: true,
    can_long_timeout: true,
    can_short_timeout: true,
    can_un_timeout: true,
    can_unban: true
  }
  @update_attrs %{
    can_ban: false,
    can_long_timeout: false,
    can_short_timeout: false,
    can_un_timeout: false,
    can_unban: false
  }
  @invalid_attrs %{
    can_ban: nil,
    can_long_timeout: nil,
    can_short_timeout: nil,
    can_un_timeout: nil,
    can_unban: nil,
    username: "fake user"
  }

  describe "index" do
    test "lists all channel_moderators", %{conn: conn} do
      conn = get(conn, Routes.channel_moderator_path(conn, :index))
      assert html_response(conn, 200) =~ "Channel Moderators"
    end
  end

  describe "new channel_moderator" do
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.channel_moderator_path(conn, :new))
      assert html_response(conn, 200) =~ "Add Moderator"
    end
  end

  describe "create channel_moderator" do
    test "redirects to show when data is valid", %{conn: conn} do
      some_valid_user = user_fixture()

      conn =
        post(conn, Routes.channel_moderator_path(conn, :create),
          channel_moderator: Map.put(@create_attrs, :username, some_valid_user.username)
        )

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.channel_moderator_path(conn, :show, id)

      conn = get(conn, Routes.channel_moderator_path(conn, :show, id))
      assert html_response(conn, 200) =~ "Edit " <> some_valid_user.username
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.channel_moderator_path(conn, :create), channel_moderator: @invalid_attrs)

      assert html_response(conn, 200) =~ "Add Moderator"
    end
  end

  describe "edit channel_moderator" do
    setup [:create_channel_moderator]

    test "renders form for editing chosen channel_moderator", %{
      conn: conn,
      channel_moderator: channel_moderator
    } do
      conn = get(conn, Routes.channel_moderator_path(conn, :show, channel_moderator))
      assert html_response(conn, 200) =~ "Edit"
    end
  end

  describe "update channel_moderator" do
    setup [:create_channel_moderator]

    test "redirects when data is valid", %{conn: conn, channel_moderator: channel_moderator} do
      conn =
        put(conn, Routes.channel_moderator_path(conn, :update, channel_moderator),
          channel_moderator: @update_attrs
        )

      assert redirected_to(conn) == Routes.channel_moderator_path(conn, :show, channel_moderator)

      conn = get(conn, Routes.channel_moderator_path(conn, :show, channel_moderator))
      assert html_response(conn, 200) =~ "Edit"
    end
  end

  describe "delete channel_moderator" do
    setup [:create_channel_moderator]

    test "deletes chosen channel_moderator", %{conn: conn, channel_moderator: channel_moderator} do
      conn = delete(conn, Routes.channel_moderator_path(conn, :delete, channel_moderator))
      assert redirected_to(conn) == Routes.channel_moderator_path(conn, :index)

      assert_error_sent 404, fn ->
        get(conn, Routes.channel_moderator_path(conn, :show, channel_moderator))
      end
    end
  end

  defp create_channel_moderator(%{channel: channel}) do
    new_mod = user_fixture()
    {:ok, channel_moderator} = Streams.create_channel_moderator(channel, new_mod, @create_attrs)
    %{channel_moderator: channel_moderator}
  end
end
