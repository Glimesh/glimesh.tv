defmodule Glimesh.ChatTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures

  alias Glimesh.Accounts
  alias Glimesh.Chat
  alias Glimesh.Streams
  alias Glimesh.StreamModeration
  alias Glimesh.Streams.ChannelModerationLog

  describe "chat_messages" do
    alias Glimesh.Chat.ChatMessage

    @valid_attrs %{message: "some message"}
    @link_containing_attrs %{message: "https://glimesh.tv is cool"}
    @invalid_attrs %{message: nil}

    setup do
      streamer = streamer_fixture()

      %{
        channel: streamer.channel,
        streamer: streamer
      }
    end

    def chat_message_fixture(attrs \\ %{}) do
      %{channel: channel} = streamer_fixture()
      user = user_fixture()

      {:ok, chat_message} =
        Chat.create_chat_message(user, channel, attrs |> Enum.into(@valid_attrs))

      chat_message
    end

    def multiple_chat_message_fixture(attrs \\ %{num_of_messages: 10}) do
      %{channel: channel} = streamer_fixture()
      user = user_fixture()

      # Pretty janky way of creating multiple chat messages but it works
      created_messages =
        Enum.map(1..attrs.num_of_messages, fn _i ->
          Chat.create_chat_message(user, channel, attrs |> Enum.into(@valid_attrs))
        end)

      {:ok, chat_message} = List.last(created_messages)

      chat_message
    end

    test "empty_chat_message/0 returns an empty changeset" do
      assert %Ecto.Changeset{} = Chat.empty_chat_message()
    end

    test "list_chat_messages/0 returns all chat_messages" do
      chat_message = chat_message_fixture()
      assert length(Chat.list_chat_messages(chat_message.channel)) == 1
    end

    test "list_chat_messages/2 returns all chat_messages within the specified limit" do
      chat_message = multiple_chat_message_fixture()
      assert length(Chat.list_chat_messages(chat_message.channel, 8)) == 8
    end

    test "get_chat_message!/1 returns the chat_message with given id" do
      chat_message = chat_message_fixture()
      assert Chat.get_chat_message!(chat_message.id).id == chat_message.id
      assert Chat.get_chat_message!(chat_message.id).message == chat_message.message
    end

    test "create_chat_message/3 with valid data creates a chat_message", %{channel: channel} do
      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(user_fixture(), channel, @valid_attrs)

      assert chat_message.message == "some message"
    end

    test "create_chat_message/3 with valid data when the channel has links blocked creates a chat_message",
         %{channel: channel, streamer: streamer} do
      {:ok, _} = Streams.update_channel(streamer, channel, %{block_links: true})

      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(user_fixture(), channel, @valid_attrs)

      assert chat_message.message == "some message"
    end

    test "create_chat_message/3 with invalid data returns error changeset", %{channel: channel} do
      assert {:error, %Ecto.Changeset{}} =
               Chat.create_chat_message(user_fixture(), channel, @invalid_attrs)
    end

    test "create_chat_message/3 with a link when channel has links blocked returns error changeset",
         %{channel: channel, streamer: streamer} do
      {:ok, channel} = Streams.update_channel(streamer, channel, %{block_links: true})

      assert {:error, "This channel has links disabled!"} =
               Chat.create_chat_message(user_fixture(), channel, @link_containing_attrs)
    end

    test "create_chat_message/1 with a link when channel allows links returns a chat_message", %{
      channel: channel
    } do
      assert {:ok, %ChatMessage{}} =
               Chat.create_chat_message(user_fixture(), channel, %{
                 "message" => "https://glimesh.tv is cool"
               })

      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(user_fixture(), channel, @link_containing_attrs)

      assert chat_message.message == @link_containing_attrs.message
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
      streamer = streamer_fixture()

      %{
        channel: streamer.channel,
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

    test "moderator has permissions based on grants", %{
      channel: channel,
      streamer: streamer,
      moderator: moderator
    } do
      {:ok, _} =
        StreamModeration.create_channel_moderator(streamer, channel, moderator, %{
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
      streamer = streamer_fixture()

      %{
        channel: streamer.channel,
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
      assert Bodyguard.permit?(Glimesh.Chat, :short_timeout, streamer, channel)
    end

    test "moderator is a moderator", %{channel: channel, streamer: streamer, moderator: moderator} do
      {:ok, _} =
        StreamModeration.create_channel_moderator(streamer, channel, moderator, %{
          can_short_timeout: true,
          can_long_timeout: false,
          can_ban: false
        })

      assert Chat.is_moderator?(channel, moderator)
    end
  end

  describe "bans and timeouts" do
    setup do
      streamer = streamer_fixture()
      moderator = user_fixture()
      # Banned user fixtures
      banned_streamer = streamer_fixture(%{is_banned: true})

      {:ok, _} =
        StreamModeration.create_channel_moderator(streamer, streamer.channel, moderator, %{
          can_short_timeout: true,
          can_long_timeout: true,
          can_ban: true,
          can_delete: true
        })

      %{
        channel: streamer.channel,
        streamer: streamer,
        banned_streamer: banned_streamer,
        banned_channel: banned_streamer.channel,
        moderator: moderator,
        user: user_fixture()
      }
    end

    test "global account ban prohibits chat", %{channel: channel} do
      user = user_fixture(%{is_banned: true})

      assert {:error, "You are banned from Glimesh."} =
               Chat.create_chat_message(user, channel, %{message: "not allowed?"})
    end

    test "global account ban prohibits streamer from chat", %{
      banned_channel: banned_channel,
      banned_streamer: banned_streamer
    } do
      assert {:error, "You are banned from Glimesh."} =
               Chat.create_chat_message(banned_streamer, banned_channel, %{
                 message: "not allowed?"
               })
    end

    test "times out a user and removes messages successfully", %{
      channel: channel,
      moderator: moderator,
      user: user
    } do
      {:ok, _} = Chat.create_chat_message(user, channel, %{message: "bad message"})
      {:ok, _} = Chat.create_chat_message(moderator, channel, %{message: "good message"})
      assert length(Chat.list_chat_messages(channel)) == 2

      {:ok, _} = Chat.short_timeout_user(moderator, channel, user)
      assert length(Chat.list_chat_messages(channel)) == 1
    end

    test "delete_message/4 deletes message", %{channel: channel, moderator: moderator, user: user} do
      {:ok, bad_message} = Chat.create_chat_message(user, channel, %{message: "bad message"})
      {:ok, _} = Chat.create_chat_message(moderator, channel, %{message: "good message"})
      assert length(Chat.list_chat_messages(channel)) == 2

      {:ok, _} = Chat.delete_message(moderator, channel, user, bad_message)
      assert length(Chat.list_chat_messages(channel)) == 1
    end

    test "short_timeout_user prevents a new message", %{
      channel: channel,
      moderator: moderator,
      user: user
    } do
      {:ok, _} = Chat.short_timeout_user(moderator, channel, user)

      assert {:error, "You are banned from this channel for 5 more minutes."} =
               Chat.create_chat_message(user, channel, %{message: "not allowed?"})
    end

    test "long_timeout_user prevents a new message", %{
      channel: channel,
      moderator: moderator,
      user: user
    } do
      {:ok, _} = Chat.long_timeout_user(moderator, channel, user)

      assert {:error, "You are banned from this channel for 15 more minutes."} =
               Chat.create_chat_message(user, channel, %{message: "not allowed?"})
    end

    test "ban_user prevents a new message", %{
      channel: channel,
      moderator: moderator,
      user: user
    } do
      {:ok, _} = Chat.ban_user(moderator, channel, user)

      assert {:error, "You are permanently banned from this channel."} =
               Chat.create_chat_message(user, channel, %{message: "not allowed?"})
    end

    test "adds log of mod actions", %{channel: channel, moderator: moderator, user: user} do
      assert {:ok, record} = Chat.short_timeout_user(moderator, channel, user)

      assert record.channel.id == channel.id
      assert record.moderator.id == moderator.id
      assert record.user.id == user.id
      assert record.action == "short_timeout"

      assert {:ok, %ChannelModerationLog{action: "long_timeout"}} =
               Chat.long_timeout_user(moderator, channel, user)

      assert {:ok, %ChannelModerationLog{action: "ban"}} = Chat.ban_user(moderator, channel, user)
    end

    test "moderation privileges are required to timeout", %{
      channel: channel,
      user: user
    } do
      assert {:error, :unauthorized} == Chat.short_timeout_user(user, channel, user)
      assert {:error, :unauthorized} == Chat.long_timeout_user(user, channel, user)
      assert {:error, :unauthorized} == Chat.ban_user(user, channel, user)
      assert {:error, :unauthorized} == Chat.unban_user(user, channel, user)
    end

    test "admin can perform all mod actions", %{
      channel: channel,
      user: user
    } do
      admin = admin_fixture()

      assert {:ok, _} = Chat.short_timeout_user(admin, channel, user)
      assert {:ok, _} = Chat.long_timeout_user(admin, channel, user)
      assert {:ok, _} = Chat.ban_user(admin, channel, user)
      assert {:ok, _} = Chat.unban_user(admin, channel, user)
    end

    test "streamer can perform all mod actions", %{
      channel: channel,
      streamer: streamer,
      user: user
    } do
      assert {:ok, _} = Chat.short_timeout_user(streamer, channel, user)
      assert {:ok, _} = Chat.long_timeout_user(streamer, channel, user)
      assert {:ok, _} = Chat.ban_user(streamer, channel, user)
      assert {:ok, _} = Chat.unban_user(streamer, channel, user)
    end
  end

  describe "chat settings button" do
    test "toggle timestamp button toggles timestamps" do
      user = user_fixture()
      user_preferences = Accounts.get_user_preference!(user)
      assert user_preferences.show_timestamps == false

      {:ok, user_preferences} =
        Accounts.update_user_preference(user_preferences, %{show_timestamps: true})

      assert user_preferences.show_timestamps == true
    end

    test "toggle mod icons button toggles mod icons" do
      user = user_fixture()
      user_preferences = Accounts.get_user_preference!(user)
      assert user_preferences.show_mod_icons == true

      {:ok, user_preferences} =
        Accounts.update_user_preference(user_preferences, %{show_mod_icons: false})

      assert user_preferences.show_mod_icons == false
    end
  end

  describe "chat safety & security" do
    alias Glimesh.Chat.ChatMessage

    setup do
      streamer = streamer_fixture()

      %{
        channel: streamer.channel,
        streamer: streamer
      }
    end

    test "create_chat_message/3 with an account under 3 hours old fails when configured",
         %{channel: channel, streamer: streamer} do
      {:ok, channel} = Streams.update_channel(streamer, channel, %{minimum_account_age: 3})

      assert {:error, "You must wait 180 more minutes to chat."} =
               Chat.create_chat_message(user_fixture(), channel, "Hello world")
    end

    test "create_chat_message/3 with an unverified account fails when configured ",
         %{channel: channel, streamer: streamer} do
      {:ok, channel} = Streams.update_channel(streamer, channel, %{require_confirmed_email: true})

      assert {:error, "You must confirm your email address before chatting."} =
               Chat.create_chat_message(user_fixture(), channel, "Hello world")
    end
  end

  describe "chat safety & security" do
    alias Glimesh.Chat.ChatMessage

    setup do
      streamer = streamer_fixture()

      %{
        channel: streamer.channel,
        streamer: streamer
      }
    end

    test "create_chat_message/3 with an account under 3 hours old fails when configured",
         %{channel: channel, streamer: streamer} do
      {:ok, channel} = Streams.update_channel(streamer, channel, %{minimum_account_age: 3})

      assert {:error, "You must wait 180 more minutes to chat."} =
               Chat.create_chat_message(user_fixture(), channel, "Hello world")
    end

    test "create_chat_message/3 with an unverified account fails when configured ",
         %{channel: channel, streamer: streamer} do
      {:ok, channel} = Streams.update_channel(streamer, channel, %{require_confirmed_email: true})

      assert {:error, "You must confirm your email address before chatting."} =
               Chat.create_chat_message(user_fixture(), channel, "Hello world")
    end
  end
end
