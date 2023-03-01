defmodule GlimeshWeb.ChannelModeratorControllerTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  alias Glimesh.StreamModeration
  alias Glimesh.Streams.ChannelModerationLog

  @create_attrs %{
    can_ban: true,
    can_long_timeout: true,
    can_short_timeout: true,
    can_un_timeout: true,
    can_unban: true,
    is_editor: true
  }
  @update_attrs %{
    can_ban: false,
    can_long_timeout: false,
    can_short_timeout: false,
    can_un_timeout: false,
    can_unban: false,
    is_editor: false
  }
  @invalid_attrs %{
    can_ban: nil,
    can_long_timeout: nil,
    can_short_timeout: nil,
    can_un_timeout: nil,
    can_unban: nil,
    is_editor: nil,
    username: "fake user"
  }

  describe "unauthorized user" do
    setup [:register_and_log_in_streamer]

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

      conn = get(conn, ~p"/users/settings/channel/mods/#{mod.id}")
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
          ~p"/users/settings/channel/mods/#{mod.id}",
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

      conn = delete(conn, ~p"/users/settings/channel/mods/#{mod.id}")
      assert response(conn, 403)
    end
  end

  setup :register_and_log_in_streamer

  describe "index" do
    test "lists all channel_moderators", %{conn: conn} do
      conn = get(conn, ~p"/users/settings/channel/mods")
      assert html_response(conn, 200) =~ "Channel Moderators"
    end

    test "lists all moderation log entries", %{conn: conn, user: user, channel: channel} do
      %{channel_moderator: channel_moderator} =
        create_channel_moderator(%{channel: channel, user: user})

      ChannelModerationLog.changeset(
        %ChannelModerationLog{
          channel: channel,
          moderator: channel_moderator.user,
          user: user_fixture()
        },
        %{action: "delete_message"}
      )
      |> Glimesh.Repo.insert()

      ChannelModerationLog.changeset(
        %ChannelModerationLog{
          channel: channel,
          moderator: channel_moderator.user,
          user: nil
        },
        %{action: "edit_title_and_tags"}
      )
      |> Glimesh.Repo.insert()

      conn = get(conn, ~p"/users/settings/channel/mods")
      response = assert html_response(conn, 200)
      assert response =~ "delete_message"
      assert response =~ "edit_title_and_tags"
    end
  end

  describe "unban user" do
    test "successfully unbans a valid user", %{conn: conn} do
      some_valid_user = user_fixture()
      conn = get(conn, ~p"/users/settings/channel/mods")

      # Need to actually ban the user first
      channel = Glimesh.ChannelLookups.get_channel_for_user(conn.assigns.current_user)
      {:ok, result} = Glimesh.Chat.ban_user(conn.assigns.current_user, channel, some_valid_user)
      assert result.action == "ban"

      # Now that we've confirmed they're banned we unban
      conn = delete(conn, ~p"/users/settings/channel/mods/unban_user/#{some_valid_user.username}")

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "User unbanned successfully"

      response = html_response(get(conn, ~p"/users/settings/channel/mods"), 200)
      refute response == some_valid_user.username
    end
  end

  describe "new channel_moderator" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/users/settings/channel/mods/new")
      assert html_response(conn, 200) =~ "Add Moderator"
    end
  end

  describe "create channel_moderator" do
    test "redirects to show when data is valid", %{conn: conn} do
      some_valid_user = user_fixture()

      conn =
        post(conn, ~p"/users/settings/channel/mods",
          channel_moderator: Map.put(@create_attrs, :username, some_valid_user.username)
        )

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/users/settings/channel/mods/#{id}"

      conn = get(conn, ~p"/users/settings/channel/mods/#{id}")
      assert html_response(conn, 200) =~ "Edit " <> some_valid_user.username
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/users/settings/channel/mods", channel_moderator: @invalid_attrs)

      assert html_response(conn, 200) =~ "Add Moderator"
    end
  end

  describe "edit channel_moderator" do
    setup [:create_channel_moderator]

    test "renders form for editing chosen channel_moderator", %{
      conn: conn,
      channel_moderator: channel_moderator
    } do
      conn = get(conn, ~p"/users/settings/channel/mods/#{channel_moderator.id}")
      assert html_response(conn, 200) =~ "Edit"
    end

    test "renders form and moderation log", %{
      conn: conn,
      channel_moderator: channel_moderator,
      channel: channel
    } do
      ChannelModerationLog.changeset(
        %ChannelModerationLog{
          channel: channel,
          moderator: channel_moderator.user,
          user: user_fixture()
        },
        %{action: "delete_message"}
      )
      |> Glimesh.Repo.insert()

      ChannelModerationLog.changeset(
        %ChannelModerationLog{
          channel: channel,
          moderator: channel_moderator.user,
          user: nil
        },
        %{action: "edit_title_and_tags"}
      )
      |> Glimesh.Repo.insert()

      conn = get(conn, ~p"/users/settings/channel/mods/#{channel_moderator.id}")
      response = html_response(conn, 200)
      assert response =~ "delete_message"
      assert response =~ "edit_title_and_tags"
    end
  end

  describe "update channel_moderator" do
    setup [:create_channel_moderator]

    test "redirects when data is valid", %{conn: conn, channel_moderator: channel_moderator} do
      conn =
        put(conn, ~p"/users/settings/channel/mods/#{channel_moderator.id}",
          channel_moderator: @update_attrs
        )

      assert redirected_to(conn) == ~p"/users/settings/channel/mods/#{channel_moderator.id}"

      conn = get(conn, ~p"/users/settings/channel/mods/#{channel_moderator.id}")
      assert html_response(conn, 200) =~ "Edit"
    end
  end

  describe "delete channel_moderator" do
    setup [:create_channel_moderator]

    test "deletes chosen channel_moderator", %{conn: conn, channel_moderator: channel_moderator} do
      conn = delete(conn, ~p"/users/settings/channel/mods/#{channel_moderator.id}")
      assert redirected_to(conn) == ~p"/users/settings/channel/mods"

      conn = get(conn, ~p"/users/settings/channel/mods/#{channel_moderator.id}")
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
