defmodule GlimeshWeb.ChannelModeratorControllerTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  alias Glimesh.StreamModeration

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

  describe "unauthorized user" do
    setup [:register_and_log_in_user]

    test "does not render edit form", %{conn: conn} do
      # Fixture for a different random user
      streamer = streamer_fixture()

      {:ok, mod} =
        StreamModeration.create_channel_moderator(
          streamer,
          streamer.channel,
          user_fixture(),
          @create_attrs
        )

      conn = get(conn, Routes.channel_moderator_path(conn, :show, mod.id))
      assert response(conn, 403)
    end

    test "does not allow updating", %{conn: conn} do
      # Fixture for a different random user
      streamer = streamer_fixture()

      {:ok, mod} =
        StreamModeration.create_channel_moderator(
          streamer,
          streamer.channel,
          user_fixture(),
          @create_attrs
        )

      conn =
        patch(
          conn,
          Routes.channel_moderator_path(conn, :update, mod.id),
          channel_moderator: @update_attrs
        )

      assert response(conn, 403)
    end

    test "does not allow deleting", %{conn: conn} do
      # Fixture for a different random user
      streamer = streamer_fixture()

      {:ok, mod} =
        StreamModeration.create_channel_moderator(
          streamer,
          streamer.channel,
          user_fixture(),
          @create_attrs
        )

      conn = delete(conn, Routes.channel_moderator_path(conn, :delete, mod.id))
      assert response(conn, 403)
    end
  end

  setup :register_and_log_in_streamer

  describe "index" do
    test "lists all channel_moderators", %{conn: conn} do
      conn = get(conn, Routes.channel_moderator_path(conn, :index))
      assert html_response(conn, 200) =~ "Channel Moderators"
    end
  end

  describe "unban user" do
    test "successfully unbans a valid user", %{conn: conn} do
      some_valid_user = user_fixture()
      conn = get(conn, Routes.channel_moderator_path(conn, :index))

      # Need to actually ban the user first
      channel = Glimesh.ChannelLookups.get_channel_for_user(conn.assigns.current_user)
      {:ok, result} = Glimesh.Chat.ban_user(conn.assigns.current_user, channel, some_valid_user)
      assert result.action == "ban"

      # Now that we've confirmed they're banned we unban
      conn =
        delete(conn, Routes.channel_moderator_path(conn, :unban_user, some_valid_user.username))
      assert get_flash(conn, :info) =~ "User unbanned successfully"

      response = html_response(get(conn, Routes.channel_moderator_path(conn, :index)), 200)
      refute response == some_valid_user.username
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

      conn = get(conn, Routes.channel_moderator_path(conn, :show, channel_moderator))
      assert response(conn, 403)
    end
  end

  defp create_channel_moderator(%{channel: channel, user: streamer}) do
    new_mod = user_fixture()

    {:ok, channel_moderator} =
      StreamModeration.create_channel_moderator(streamer, channel, new_mod, @create_attrs)

    %{channel_moderator: channel_moderator}
  end
end
