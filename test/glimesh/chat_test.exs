defmodule Glimesh.ChatTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures
  import Phoenix.HTML, only: [safe_to_string: 1]

  alias Glimesh.Chat
  alias Glimesh.Streams
  alias Glimesh.Streams.ChannelModerationLog

  describe "chat_messages" do
    alias Glimesh.Chat.ChatMessage

    @valid_attrs %{message: "some message"}
    @update_attrs %{message: "some updated message"}
    @link_containing_attrs %{message: "https://glimesh.tv is cool"}
    @invalid_attrs %{message: nil}

    def chat_message_fixture(attrs \\ %{}) do
      channel = channel_fixture()
      user = user_fixture()

      {:ok, chat_message} =
        Chat.create_chat_message(channel, user, attrs |> Enum.into(@valid_attrs))

      chat_message
    end

    test "list_chat_messages/0 returns all chat_messages" do
      chat_message = chat_message_fixture()
      assert length(Chat.list_chat_messages(chat_message.channel)) == 1
    end

    test "get_chat_message!/1 returns the chat_message with given id" do
      chat_message = chat_message_fixture()
      assert Chat.get_chat_message!(chat_message.id).id == chat_message.id
      assert Chat.get_chat_message!(chat_message.id).message == chat_message.message
    end

    test "create_chat_message/1 with valid data creates a chat_message" do
      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(channel_fixture(), user_fixture(), @valid_attrs)

      assert chat_message.message == "some message"
    end

    test "create_chat_message/1 with valid data when the channel has links blocked creates a chat_message" do
      channel = channel_fixture()
      {:ok, _} = Streams.update_channel(channel, %{block_links: true})

      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(channel_fixture(), user_fixture(), @valid_attrs)

      assert chat_message.message == "some message"
    end

    test "create_chat_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Chat.create_chat_message(channel_fixture(), user_fixture(), @invalid_attrs)
    end

    test "create_chat_message/1 with a link when channel has links blocked returns error changeset" do
      channel = channel_fixture()
      {:ok, channel} = Streams.update_channel(channel, %{block_links: true})

      assert {:error, %Ecto.Changeset{}} =
               Chat.create_chat_message(channel, user_fixture(), @link_containing_attrs)
    end

    test "create_chat_message/1 with a link when channel allows links returns a chat_message" do
      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(channel_fixture(), user_fixture(), @link_containing_attrs)

      assert chat_message.message == @link_containing_attrs.message
    end

    test "update_chat_message/2 with valid data updates the chat_message" do
      chat_message = chat_message_fixture()

      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.update_chat_message(chat_message, @update_attrs)

      assert chat_message.message == "some updated message"
    end

    test "update_chat_message/2 with invalid data returns error changeset" do
      chat_message = chat_message_fixture()
      assert {:error, %Ecto.Changeset{}} = Chat.update_chat_message(chat_message, @invalid_attrs)
      assert chat_message.id == Chat.get_chat_message!(chat_message.id).id
    end

    #    test "delete_chat_message/1 deletes the chat_message" do
    #      chat_message = chat_message_fixture()
    #      assert {:ok, %ChatMessage{}} = Chat.delete_chat_message(chat_message)
    #      assert_raise Ecto.NoResultsError, fn -> Chat.get_chat_message!(chat_message.id) end
    #    end

    test "change_chat_message/1 returns a chat_message changeset" do
      chat_message = chat_message_fixture()
      assert %Ecto.Changeset{} = Chat.change_chat_message(chat_message)
    end
  end

  describe "get_moderator_permissions/2" do
    setup do
      [channel, streamer] = channel_streamer_fixture()

      %{
        channel: channel,
        streamer: streamer,
        moderator: user_fixture(),
        user: user_fixture()
      }
    end

    test "random user has no permissions", %{channel: channel, user: user} do
      assert %{can_short_timeout: false, can_long_timeout: false, can_ban: false} =
               Chat.get_moderator_permissions(channel, user)
    end

    test "streamer has all permissions", %{channel: channel, streamer: streamer} do
      assert %{can_short_timeout: true, can_long_timeout: true, can_ban: true} =
               Chat.get_moderator_permissions(channel, streamer)
    end

    test "moderator has permissions based on grants", %{channel: channel, moderator: moderator} do
      {:ok, _} =
        Glimesh.Streams.create_channel_moderator(channel, moderator, %{
          can_short_timeout: true,
          can_long_timeout: true,
          can_ban: false
        })

      assert %{can_short_timeout: true, can_long_timeout: true, can_ban: false} =
               Chat.get_moderator_permissions(channel, moderator)
    end
  end

  describe "is_moderator/2" do
    setup do
      [channel, streamer] = channel_streamer_fixture()

      %{
        channel: channel,
        streamer: streamer,
        moderator: user_fixture(),
        user: user_fixture()
      }
    end

    test "random user is not moderator", %{channel: channel, user: user} do
      refute Chat.is_moderator?(channel, user)
    end

    test "streamer is not a moderator but can moderate", %{channel: channel, streamer: streamer} do
      refute Chat.is_moderator?(channel, streamer)
      assert Chat.can_moderate?(:can_short_timeout, channel, streamer)
    end

    test "moderator is a moderator", %{channel: channel, moderator: moderator} do
      {:ok, _} =
        Glimesh.Streams.create_channel_moderator(channel, moderator, %{
          can_short_timeout: true,
          can_long_timeout: false,
          can_ban: false
        })

      assert Chat.is_moderator?(channel, moderator)
    end
  end

  describe "bans and timeouts" do
    setup do
      [channel, streamer] = channel_streamer_fixture()
      moderator = user_fixture()

      {:ok, _} =
        Glimesh.Streams.create_channel_moderator(channel, moderator, %{
          can_short_timeout: true,
          can_long_timeout: true,
          can_ban: true
        })

      %{
        channel: channel,
        streamer: streamer,
        moderator: moderator,
        user: user_fixture()
      }
    end

    test "times out a user and removes messages successfully", %{
      channel: channel,
      moderator: moderator,
      user: user
    } do
      {:ok, _} = Chat.create_chat_message(channel, user, %{message: "bad message"})
      {:ok, _} = Chat.create_chat_message(channel, moderator, %{message: "good message"})
      assert length(Chat.list_chat_messages(channel)) == 2

      {:ok, _} = Chat.short_timeout_user(channel, moderator, user)
      assert length(Chat.list_chat_messages(channel)) == 1
    end

    test "short_timeout_user prevents a new message", %{
      channel: channel,
      moderator: moderator,
      user: user
    } do
      {:ok, _} = Chat.short_timeout_user(channel, moderator, user)

      assert {:error, changeset} =
               Chat.create_chat_message(channel, user, %{message: "not allowed?"})

      assert {"You are banned from this channel for 5 more minutes.", _} =
               changeset.errors[:message]
    end

    test "long_timeout_user prevents a new message", %{
      channel: channel,
      moderator: moderator,
      user: user
    } do
      {:ok, _} = Chat.long_timeout_user(channel, moderator, user)

      assert {:error, changeset} =
               Chat.create_chat_message(channel, user, %{message: "not allowed?"})

      assert {"You are banned from this channel for 15 more minutes.", _} =
               changeset.errors[:message]
    end

    test "ban_user prevents a new message", %{
      channel: channel,
      moderator: moderator,
      user: user
    } do
      {:ok, _} = Chat.ban_user(channel, moderator, user)

      assert {:error, changeset} =
               Chat.create_chat_message(channel, user, %{message: "not allowed?"})

      assert {"You are permanently banned from this channel.", _} = changeset.errors[:message]
    end

    test "adds log of mod actions", %{channel: channel, moderator: moderator, user: user} do
      assert {:ok, record} = Chat.short_timeout_user(channel, moderator, user)

      assert record.channel.id == channel.id
      assert record.moderator.id == moderator.id
      assert record.user.id == user.id
      assert record.action == "short_timeout"

      assert {:ok, %ChannelModerationLog{action: "long_timeout"}} =
               Chat.long_timeout_user(channel, moderator, user)

      assert {:ok, %ChannelModerationLog{action: "ban"}} = Chat.ban_user(channel, moderator, user)
    end

    test "moderation privileges are required to timeout", %{
      channel: channel,
      user: user
    } do
      assert_raise RuntimeError,
                   "User does not have permission to moderate.",
                   fn -> Chat.short_timeout_user(channel, user, user) end

      assert_raise RuntimeError,
                   "User does not have permission to moderate.",
                   fn -> Chat.long_timeout_user(channel, user, user) end

      assert_raise RuntimeError,
                   "User does not have permission to moderate.",
                   fn -> Chat.ban_user(channel, user, user) end

      assert_raise RuntimeError,
                   "User does not have permission to moderate.",
                   fn -> Chat.unban_user(channel, user, user) end
    end

    test "admin can perform all mod actions", %{
      channel: channel,
      user: user
    } do
      admin = admin_fixture()

      assert {:ok, _} = Chat.short_timeout_user(channel, admin, user)
      assert {:ok, _} = Chat.long_timeout_user(channel, admin, user)
      assert {:ok, _} = Chat.ban_user(channel, admin, user)
      assert {:ok, _} = Chat.unban_user(channel, admin, user)
    end

    test "streamer can perform all mod actions", %{
      channel: channel,
      streamer: streamer,
      user: user
    } do
      assert {:ok, _} = Chat.short_timeout_user(channel, streamer, user)
      assert {:ok, _} = Chat.long_timeout_user(channel, streamer, user)
      assert {:ok, _} = Chat.ban_user(channel, streamer, user)
      assert {:ok, _} = Chat.unban_user(channel, streamer, user)
    end
  end

  describe "chat rendering" do
    setup do
      [channel, streamer] = channel_streamer_fixture()
      moderator = user_fixture()

      {:ok, _} =
        Glimesh.Streams.create_channel_moderator(channel, moderator, %{
          can_short_timeout: true,
          can_long_timeout: true,
          can_ban: true
        })

      %{
        channel: channel,
        streamer: streamer,
        moderator: moderator,
        user: user_fixture()
      }
    end

    test "renders appropriate tags for admins", %{channel: channel} do
      admin = admin_fixture()

      assert safe_to_string(Glimesh.Chat.render_username(admin)) =~ "Glimesh Staff"

      assert safe_to_string(Glimesh.Chat.render_avatar(admin)) =~
               "avatar-ring platform-admin-ring"

      assert Glimesh.Chat.render_channel_badge(channel, admin) == ""
    end

    test "renders appropriate tags for moderator", %{channel: channel, moderator: moderator} do
      {:ok, _} = Glimesh.Streams.create_channel_moderator(channel, moderator, %{})

      assert safe_to_string(Glimesh.Chat.render_channel_badge(channel, moderator)) =~ "Moderator"

      assert safe_to_string(Glimesh.Chat.render_channel_badge(channel, moderator)) =~
               "badge badge-info"
    end
  end
end
