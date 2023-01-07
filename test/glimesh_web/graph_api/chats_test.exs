defmodule GlimeshWeb.GraphApi.ChatsTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  import Glimesh.EmotesFixtures
  import Glimesh.Support.GraphqlHelper

  alias Glimesh.Streams

  @create_chat_message_mutation """
  mutation CreateChatMessage($channelId: ID!, $message: ChatMessageInput!) {
    createChatMessage(channelId: $channelId, message: $message) {
      message
      user {
        username
      }
      tokens {
        type
        text
        ... on EmoteToken {
          src
        }
      }
    }
  }
  """
  @create_chat_message_with_metadata_mutation """
  mutation CreateChatMessage($channelId: ID!, $message: ChatMessageInput!) {
    createChatMessage(channelId: $channelId, message: $message) {
      message
      metadata {
        admin
        streamer
        moderator
        subscriber
        platform_founder_subscriber
        platform_supporter_subscriber
      }
    }
  }
  """

  @short_timeout_mutation """
  mutation ShortTimeoutUser($channelId: ID!, $userId: ID!) {
    shortTimeoutUser(channelId: $channelId, userId: $userId) {
      moderator {
        username
      }
      user {
        username
      }
      action
    }
  }
  """

  @long_timeout_mutation """
  mutation LongTimeoutUser($channelId: ID!, $userId: ID!) {
    longTimeoutUser(channelId: $channelId, userId: $userId) {
      moderator {
        username
      }
      user {
        username
      }
      action
    }
  }
  """

  @ban_user_mutation """
  mutation BanUser($channelId: ID!, $userId: ID!) {
    banUser(channelId: $channelId, userId: $userId) {
      moderator {
        username
      }
      user {
        username
      }
      action
    }
  }
  """

  @unban_user_mutation """
  mutation UnbanUser($channelId: ID!, $userId: ID!) {
    unbanUser(channelId: $channelId, userId: $userId) {
      moderator {
        username
      }
      user {
        username
      }
      action
    }
  }
  """

  @delete_chat_message_mutation """
  mutation DeleteChatmessage($channelId: ID!, $messageId: ID!) {
    deleteChatMessage(channelId: $channelId, messageId: $messageId) {
      moderator {
        username
      }
      user {
        username
      }
      action
    }
  }
  """
  @get_chatter_username_autocomplete_query """
  query ChatAutocomplete($channelId: ID!, $partialUsernames: [String]!) {
    autocompleteRecentChatUsers(channelId: $channelId, partialUsernames: $partialUsernames)
  }
  """

  describe "chat api without scope" do
    setup [:create_user, :create_channel]

    setup context do
      create_token_and_return_context(context.conn, context.user, "public")
    end

    test "cannot send a chat message", %{conn: conn, channel: channel} do
      resp =
        run_query(conn, @create_chat_message_mutation, %{
          channelId: "#{channel.id}",
          message: %{
            message: "Hello world"
          }
        })

      assert is_nil(resp["data"]["createChatMessage"])

      assert [
               %{
                 "locations" => _,
                 "message" => "unauthorized",
                 "path" => _
               }
             ] = resp["errors"]
    end
  end

  describe "chat api with scope" do
    setup [:register_and_set_user_token, :create_channel, :create_emote]

    test "can send a chat message", %{conn: conn, user: user, channel: channel} do
      conn =
        post(conn, "/api/graph", %{
          "query" => @create_chat_message_mutation,
          "variables" => %{
            channelId: "#{channel.id}",
            message: %{
              message: "Hello world"
            }
          }
        })

      assert json_response(conn, 200)["data"]["createChatMessage"] == %{
               "message" => "Hello world",
               "user" => %{
                 "username" => user.username
               },
               "tokens" => [
                 %{"type" => "text", "text" => "Hello world"}
               ]
             }
    end

    test "can send a chat message and get appropriate metadata", %{
      conn: conn,
      channel: channel
    } do
      # This doesn't really belong here, but where does it belong?
      conn =
        post(conn, "/api/graph", %{
          "query" => @create_chat_message_with_metadata_mutation,
          "variables" => %{
            channelId: "#{channel.id}",
            message: %{
              message: "Hello world"
            }
          }
        })

      assert json_response(conn, 200)["data"]["createChatMessage"] == %{
               "message" => "Hello world",
               "metadata" => %{
                 "admin" => false,
                 "streamer" => true,
                 "moderator" => false,
                 "subscriber" => false,
                 "platform_founder_subscriber" => false,
                 "platform_supporter_subscriber" => false
               }
             }
    end

    test "can send a chat message in different channel", %{
      conn: conn,
      user: user
    } do
      streamer = streamer_fixture()

      conn =
        post(conn, "/api/graph", %{
          "query" => @create_chat_message_mutation,
          "variables" => %{
            channelId: "#{streamer.channel.id}",
            message: %{
              message: "Hello world"
            }
          }
        })

      assert json_response(conn, 200)["data"]["createChatMessage"] == %{
               "message" => "Hello world",
               "user" => %{
                 "username" => user.username
               },
               "tokens" => [
                 %{"type" => "text", "text" => "Hello world"}
               ]
             }
    end

    test "can send a emote based message", %{
      conn: conn,
      user: user,
      channel: channel,
      emote: emote
    } do
      conn =
        post(conn, "/api/graph", %{
          "query" => @create_chat_message_mutation,
          "variables" => %{
            channelId: "#{channel.id}",
            message: %{
              message: "Hello :glimchef: world!"
            }
          }
        })

      expected_url = Glimesh.Emotes.full_url(emote)

      assert json_response(conn, 200)["data"]["createChatMessage"] == %{
               "message" => "Hello :glimchef: world!",
               "user" => %{
                 "username" => user.username
               },
               "tokens" => [
                 %{"type" => "text", "text" => "Hello "},
                 %{
                   "type" => "emote",
                   "text" => ":glimchef:",
                   "src" => expected_url
                 },
                 %{"type" => "text", "text" => " world!"}
               ]
             }
    end

    test "can perform moderation actions", %{conn: conn, user: streamer, channel: channel} do
      user_to_ban = user_fixture()

      conn =
        post(conn, "/api/graph", %{
          "query" => @ban_user_mutation,
          "variables" => %{
            channelId: "#{channel.id}",
            userId: "#{user_to_ban.id}"
          }
        })

      assert json_response(conn, 200)["data"]["banUser"] == %{
               "action" => "ban",
               "moderator" => %{
                 "username" => streamer.username
               },
               "user" => %{
                 "username" => user_to_ban.username
               }
             }

      assert {:error, "You are permanently banned from this channel."} =
               Glimesh.Chat.create_chat_message(user_to_ban, channel, %{message: "Hello world"})
    end

    test "can short timeout users", %{conn: conn, channel: channel} do
      user_to_ban = user_fixture()

      resp =
        run_query(conn, @short_timeout_mutation, %{
          channelId: "#{channel.id}",
          userId: "#{user_to_ban.id}"
        })

      assert resp["data"]["shortTimeoutUser"]["action"] == "short_timeout"

      assert {:error, "You are banned from this channel for 5 more minutes."} =
               Glimesh.Chat.create_chat_message(user_to_ban, channel, %{message: "Hello world"})
    end

    test "can long timeout users", %{conn: conn, channel: channel} do
      user_to_ban = user_fixture()

      resp =
        run_query(conn, @long_timeout_mutation, %{
          channelId: "#{channel.id}",
          userId: "#{user_to_ban.id}"
        })

      assert resp["data"]["longTimeoutUser"]["action"] == "long_timeout"

      assert {:error, "You are banned from this channel for 15 more minutes."} =
               Glimesh.Chat.create_chat_message(user_to_ban, channel, %{message: "Hello world"})
    end

    test "can unban users", %{conn: conn, user: streamer, channel: channel} do
      user_to_unban = user_fixture()
      Glimesh.Chat.ban_user(streamer, channel, user_to_unban)

      resp =
        run_query(conn, @unban_user_mutation, %{
          channelId: "#{channel.id}",
          userId: "#{user_to_unban.id}"
        })

      assert resp["data"]["unbanUser"]["action"] == "unban"

      assert {:ok, %{message: message}} =
               Glimesh.Chat.create_chat_message(user_to_unban, channel, %{message: "Hello world"})

      assert message == "Hello world"
    end

    test "can delete chat messages", %{conn: conn, channel: channel} do
      bad_user = user_fixture()

      assert {:ok, %{id: chat_message_id}} =
               Glimesh.Chat.create_chat_message(bad_user, channel, %{
                 message: "This is a bad message"
               })

      resp =
        run_query(conn, @delete_chat_message_mutation, %{
          channelId: "#{channel.id}",
          messageId: "#{chat_message_id}"
        })

      assert resp["data"]["deleteChatMessage"]["action"] == "delete_message"

      messages = Glimesh.Chat.list_chat_messages(channel)

      Enum.each(messages, fn m ->
        assert m.message !== "This is a bad message"
      end)
    end

    test "can get autocomplete suggestions", %{conn: conn, channel: channel} do
      %{
        user_one: user_one,
        user_two: user_two
      } = setup_chat_users(conn, channel)

      user_one_partial = String.slice(user_one.displayname, 0, 3)
      user_two_partial = String.slice(user_two.displayname, 1, 3)

      conn =
        post(conn, "/api/graph", %{
          "query" => @get_chatter_username_autocomplete_query,
          "variables" => %{
            channelId: "#{channel.id}",
            partialUsernames: [user_one_partial, user_two_partial]
          }
        })

      assert json_response(conn, 200)["data"]["autocompleteRecentChatUsers"] == [
               user_one.displayname,
               user_two.displayname
             ]
    end

    test "autocomplete suggestions will not show lurkers", %{conn: conn, channel: channel} do
      %{
        lurk_user: lurk_user
      } = setup_chat_users_with_lurker(conn, channel)

      lurk_partial = String.slice(lurk_user.displayname, 0, 3)

      conn =
        post(conn, "/api/graph", %{
          "query" => @get_chatter_username_autocomplete_query,
          "variables" => %{
            channelId: "#{channel.id}",
            partialUsernames: [lurk_partial]
          }
        })

      refute json_response(conn, 200)["data"]["autocompleteRecentChatUsers"] == [
               lurk_user.displayname
             ]
    end
  end

  describe "chat api with app client credentials" do
    setup [:register_and_set_user_token, :create_channel]

    test "can send a chat message", %{conn: conn, user: user, channel: channel} do
      conn =
        post(conn, "/api/graph", %{
          "query" => @create_chat_message_mutation,
          "variables" => %{
            channelId: "#{channel.id}",
            message: %{
              message: "Hello world"
            }
          }
        })

      assert json_response(conn, 200)["data"]["createChatMessage"] == %{
               "message" => "Hello world",
               "user" => %{
                 "username" => user.username
               },
               "tokens" => [
                 %{"type" => "text", "text" => "Hello world"}
               ]
             }
    end
  end

  def create_user(_) do
    %{user: user_fixture()}
  end

  def create_channel(%{user: user}) do
    {:ok, channel} = Streams.create_channel(user)
    %{channel: channel}
  end

  def create_emote(_) do
    %{emote: static_global_emote_fixture()}
  end

  defp setup_chat_users(conn, channel) do
    %{conn: user_one_conn, user: user_one} = register_and_log_in_user(%{conn: conn})
    %{conn: user_two_conn, user: user_two} = register_and_log_in_user(%{conn: conn})
    Glimesh.Chat.create_chat_message(user_one, channel, %{message: "test message"})
    Glimesh.Chat.create_chat_message(user_two, channel, %{message: "test another message"})

    Glimesh.Presence.track_presence(
      self(),
      Streams.get_subscribe_topic(:chatters, channel.id),
      user_one.id,
      %{
        typing: false,
        username: user_one.username,
        avatar: Glimesh.Avatar.url({user_one.avatar, user_one}, :original),
        user_id: user_one.id,
        size: 48
      }
    )

    Glimesh.Presence.track_presence(
      self(),
      Streams.get_subscribe_topic(:chatters, channel.id),
      user_two.id,
      %{
        typing: false,
        username: user_two.username,
        avatar: Glimesh.Avatar.url({user_two.avatar, user_two}, :original),
        user_id: user_two.id,
        size: 48
      }
    )

    %{
      user_one: user_one,
      user_two: user_two,
      user_one_conn: user_one_conn,
      user_two_conn: user_two_conn
    }
  end

  defp setup_chat_users_with_lurker(conn, channel) do
    %{
      user_one: user_one,
      user_two: user_two,
      user_one_conn: user_one_conn,
      user_two_conn: user_two_conn
    } = setup_chat_users(conn, channel)

    %{conn: user_three_conn, user: user_three} = register_and_log_in_user(%{conn: conn})

    Glimesh.Presence.track_presence(
      self(),
      Streams.get_subscribe_topic(:chatters, channel.id),
      user_three.id,
      %{
        typing: false,
        username: user_three.username,
        avatar: Glimesh.Avatar.url({user_three.avatar, user_three}, :original),
        user_id: user_three.id,
        size: 48
      }
    )

    %{
      user_one: user_one,
      user_two: user_two,
      lurk_user: user_three,
      user_one_conn: user_one_conn,
      user_two_conn: user_two_conn,
      lurk_user_conn: user_three_conn
    }
  end
end
