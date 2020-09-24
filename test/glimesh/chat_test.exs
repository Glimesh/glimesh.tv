defmodule Glimesh.ChatTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures
  alias Ecto.Changeset
  alias Glimesh.Accounts.User
  alias Glimesh.Chat
  alias Glimesh.Streams
  alias Glimesh.Streams.ChannelModerationLog

  describe "chat_messages" do
    alias Glimesh.Chat.ChatMessage

    @valid_attrs %{message: "some message"}
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
      {:ok, channel} = Streams.update_channel(channel, %{block_links: true})

      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(channel_fixture(), user_fixture(), @valid_attrs)

      assert chat_message.message == "some message"
    end

    test "create_chat_message/1 with invalid data returns error changeset" do
      assert {:error, %Changeset{}} =
               Chat.create_chat_message(channel_fixture(), user_fixture(), @invalid_attrs)
    end

    test "create_chat_message/1 with a link when channel has links blocked returns error changeset" do
      channel = channel_fixture()
      {:ok, channel} = Streams.update_channel(channel, %{block_links: true})

      assert {:error, %Changeset{}} =
               Chat.create_chat_message(channel, user_fixture(), @link_containing_attrs)
    end

    test "create_chat_message/1 with a link when channel allows links returns a chat_message" do
      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(channel_fixture(), user_fixture(), @link_containing_attrs)

      assert chat_message.message == @link_containing_attrs.message
    end

    test "user_in_message/2 check if user is in message" do
      user = user_fixture()

      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(channel_fixture(), user_fixture(), %{
                 message: "#{@valid_attrs.message} #{user.username}"
               })

      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(channel_fixture(), user_fixture(), %{
                 message: "#{@valid_attrs.message} @#{user.username}"
               })

      assert Chat.user_in_message(user, chat_message)
    end

    test "user_in_message/2 check if user is in message but is same user" do
      user = user_fixture()

      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(channel_fixture(), user, %{
                 message: "#{@valid_attrs.message} #{user.username}"
               })

      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(channel_fixture(), user, %{
                 message: "#{@valid_attrs.message} @#{user.username}"
               })

      assert false == Chat.user_in_message(user, chat_message)
    end

    test "user_in_message/2 check if user is not in message" do
      user = user_fixture()

      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(channel_fixture(), user, @valid_attrs)

      assert false == Chat.user_in_message(user, chat_message)
    end

    test "user_in_message/2 check if right response on nil user" do
      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(channel_fixture(), user_fixture(), @valid_attrs)

      assert false == Chat.user_in_message(nil, chat_message)
    end

    test "render_stream_badge/2 check if badge should be nothing" do
      assert Chat.render_stream_badge(channel_fixture(), user_fixture()) == ""
    end

    test "render_stream_badge/2 check if badge should be system" do
      assert {:safe, html_list} =
               Chat.render_stream_badge(channel_fixture(), %User{id: 0, is_admin: false})

      assert [
               60,
               "span",
               [[32, "class", 61, 34, "badge badge-danger", 34]],
               62,
               "System",
               60,
               47,
               "span",
               62
             ] = html_list
    end

    test "render_stream_badge/2 check if badge should be moderator" do
      channel = channel_fixture()
      user = user_fixture()
      assert {:ok, _channel_moderator} = Streams.add_moderator(channel, user)
      assert {:safe, html_list} = Chat.render_stream_badge(channel, user)

      assert [
               60,
               "span",
               [[32, "class", 61, 34, "badge badge-info", 34]],
               62,
               "Moderator",
               60,
               47,
               "span",
               62
             ] = html_list
    end

    test "render_stream_badge/2 check if badge should be streamer" do
      channel = channel_fixture()
      assert {:safe, html_list} = Chat.render_stream_badge(channel, channel.user)

      assert [
               60,
               "span",
               [[32, "class", 61, 34, "badge badge-light", 34]],
               62,
               "Streamer",
               60,
               47,
               "span",
               62
             ] = html_list
    end

    test "render_global_badge/1 check if badge should be Team Glimesh" do
      assert {:safe, html_list} = Chat.render_global_badge(%User{id: 0, is_admin: true})

      assert [
               60,
               "span",
               [[32, "class", 61, 34, "badge badge-danger", 34]],
               62,
               "Team Glimesh",
               60,
               47,
               "span",
               62
             ] = html_list
    end

    test "render_global_badge/1 check if badge should be nothing" do
      assert Chat.render_global_badge(user_fixture()) == ""
    end

    test "can_moderate/2 check if nils are false" do
      assert Chat.can_moderate?(nil, nil) == false
    end

    test "can_moderate/2 check if nil user is false" do
      assert Chat.can_moderate?(channel_fixture(), nil) == false
    end

    test "can_moderate/2 check if user is not moderator" do
      assert Chat.can_moderate?(channel_fixture(), user_fixture()) == false
    end

    test "can_moderate/2 check if user is moderator" do
      channel = channel_fixture()
      user = user_fixture()
      assert {:ok, _channel_moderator} = Streams.add_moderator(channel, user)
      assert Chat.can_moderate?(channel, user) == true
    end

    test "can_moderate/2 check if user is streamer and there for should be moderator" do
      channel = channel_fixture()
      assert Chat.can_moderate?(channel, channel.user) == true
    end

    test "delete_chat_message/1 check if chat_message is removed" do
      chat_message = chat_message_fixture()
      assert {:ok, %ChatMessage{}} = Chat.delete_chat_message(chat_message)
      assert Chat.get_chat_message!(chat_message.id).is_visible == false
    end

    test "delete_chat_messages_for_user/2 check if chat_messages from user are removed" do
      channel = channel_fixture()
      user = user_fixture()

      assert {:ok, %ChatMessage{} = chat_message_one} =
               Chat.create_chat_message(channel, user, @valid_attrs)

      assert {:ok, %ChatMessage{} = chat_message_two} =
               Chat.create_chat_message(channel, user, @valid_attrs)

      assert {:ok, %ChatMessage{} = chat_message_three} =
               Chat.create_chat_message(channel, user, @valid_attrs)

      assert {:ok, %ChatMessage{} = chat_message_flour} =
               Chat.create_chat_message(channel, user, @valid_attrs)

      assert {:ok, %ChatMessage{} = chat_message_five} =
               Chat.create_chat_message(channel, user, @valid_attrs)

      assert {5, nil} = Chat.delete_chat_messages_for_user(channel, user)

      assert Chat.get_chat_message!(chat_message_one.id).is_visible == false &&
               Chat.get_chat_message!(chat_message_two.id).is_visible == false &&
               Chat.get_chat_message!(chat_message_three.id).is_visible == false &&
               Chat.get_chat_message!(chat_message_flour.id).is_visible == false &&
               Chat.get_chat_message!(chat_message_five.id).is_visible == false
    end

    test "delete_all_chat_messages/1 check if chat_messages from channel are removed" do
      channel = channel_fixture()
      user = user_fixture()

      assert {:ok, %ChatMessage{} = chat_message_one} =
               Chat.create_chat_message(channel, user, @valid_attrs)

      assert {:ok, %ChatMessage{} = chat_message_two} =
               Chat.create_chat_message(channel, user, @valid_attrs)

      assert {:ok, %ChatMessage{} = chat_message_three} =
               Chat.create_chat_message(channel, channel.user, @valid_attrs)

      assert {:ok, %ChatMessage{} = chat_message_four} =
               Chat.create_chat_message(channel, channel.user, @valid_attrs)

      assert {:ok, %ChatMessage{} = chat_message_five} =
               Chat.create_chat_message(channel, user, @valid_attrs)

      assert {5, nil} = Chat.delete_all_chat_messages(channel)

      assert Chat.get_chat_message!(chat_message_one.id).is_visible == false &&
               Chat.get_chat_message!(chat_message_two.id).is_visible == false &&
               Chat.get_chat_message!(chat_message_three.id).is_visible == false &&
               Chat.get_chat_message!(chat_message_four.id).is_visible == false &&
               Chat.get_chat_message!(chat_message_five.id).is_visible == false
    end

    test "change_chat_message/1 returns a chat_message changeset" do
      chat_message = chat_message_fixture()
      assert %Changeset{} = Chat.change_chat_message(chat_message)
    end

    test "empty_chat_message/0 returns an empty chat_message" do
      assert %Changeset{} = Chat.empty_chat_message()
    end

    test "ban_user/3 try and post while banned" do
      channel = channel_fixture()

      assert {:ok, %ChannelModerationLog{} = moderation_log} =
               Chat.ban_user(channel, channel.user, user_fixture())

      assert {:error, %Changeset{} = changeset} =
               Chat.create_chat_message(channel, moderation_log.user, @valid_attrs)

      assert [message: message] = changeset.errors
      assert {error_text, [validation: :required]} = message
      assert error_text == "You are currently banned or timedout."
    end

    test "ban_user/3 and then unban_user/3 and try to post" do
      channel = channel_fixture()

      assert {:ok, %ChannelModerationLog{} = moderation_log} =
               Chat.ban_user(channel, channel.user, user_fixture())

      assert {:ok, %ChannelModerationLog{}} =
               Chat.unban_user(channel, channel.user, moderation_log.user)

      assert {:ok, %ChatMessage{}} =
               Chat.create_chat_message(channel, moderation_log.user, @valid_attrs)
    end

    test "ban_user/3 but does not have moderator privilegies" do
      channel = channel_fixture()

      assert {:error, %Changeset{} = changeset} =
               Chat.ban_user(channel, user_fixture(), user_fixture())

      assert [message: message] = changeset.errors
      assert {error_text, [validation: :required]} = message
      assert error_text == "You do not have permission to moderate."
    end

    test "unban_user/3 but does not have moderator privilegies" do
      channel = channel_fixture()

      assert {:error, %Changeset{} = changeset} =
               Chat.unban_user(channel, user_fixture(), user_fixture())

      assert [message: message] = changeset.errors
      assert {error_text, [validation: :required]} = message
      assert error_text == "You do not have permission to moderate."
    end

    test "clear_chat/3 but does not have moderator privilegies" do
      channel = channel_fixture()
      assert {:error, %Changeset{} = changeset} = Chat.clear_chat(channel, user_fixture())
      assert [message: message] = changeset.errors
      assert {error_text, [validation: :required]} = message
      assert error_text == "You do not have permission to moderate."
    end

    test "clear_chat/2 success" do
      channel = channel_fixture()
      assert {:ok, %ChannelModerationLog{}} = Chat.clear_chat(channel, channel.user)
    end

    test "timeout_user/4 try and post while timedout" do
      channel = channel_fixture()

      assert {:ok, %ChannelModerationLog{} = moderation_log} =
               Chat.timeout_user(
                 channel,
                 channel.user,
                 user_fixture(),
                 DateTime.add(DateTime.utc_now(), 300)
               )

      assert {:error, %Changeset{} = changeset} =
               Chat.create_chat_message(channel, moderation_log.user, @valid_attrs)

      assert [message: message] = changeset.errors
      assert {error_text, [validation: :required]} = message
      assert error_text == "You are currently banned or timedout."
    end

    test "timeout_user/4 but does not have moderator privilegies" do
      channel = channel_fixture()

      assert {:error, %Changeset{} = changeset} =
               Chat.timeout_user(
                 channel,
                 user_fixture(),
                 user_fixture(),
                 DateTime.add(DateTime.utc_now(), 300)
               )

      assert [message: message] = changeset.errors
      assert {error_text, [validation: :required]} = message
      assert error_text == "You do not have permission to moderate."
    end

    test "list_chat_user_messages/2 returns all chat_messages" do
      user_one = user_fixture()
      user_two = user_fixture()
      channel = channel_fixture()
      Chat.create_chat_message(channel, user_one, @valid_attrs)
      Chat.create_chat_message(channel, user_one, @valid_attrs)
      Chat.create_chat_message(channel, user_two, @valid_attrs)
      Chat.create_chat_message(channel, user_two, @valid_attrs)
      assert length(Chat.list_chat_user_messages(channel, user_one)) == 2
      assert length(Chat.list_chat_user_messages(channel, user_two)) == 2
    end

    test "can_create_chat_message/2 check if user can post" do
      assert Chat.can_create_chat_message(channel_fixture(), user_fixture())
    end

    test "can_create_chat_message/2 check if user cannot post" do
      channel = channel_fixture()
      user = user_fixture()
      Chat.ban_user(channel, channel.user, user)
      assert Chat.can_create_chat_message(channel, user) == false
      Chat.unban_user(channel, channel.user, user)
      Chat.timeout_user(channel, channel.user, user, DateTime.add(DateTime.utc_now(), 300))
      assert Chat.can_create_chat_message(channel, user) == false
    end
  end
end
