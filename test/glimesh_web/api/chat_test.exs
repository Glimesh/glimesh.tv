defmodule GlimeshWeb.Api.ChatTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures

  alias Glimesh.Streams

  @create_chat_message_query """
  mutation CreateChatMessage($channelId: ID!, $message: ChatMessageInput!) {
    createChatMessage(channelId: $channelId, message: $message) {
      message
      user {
        username
      }
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

  describe "chat api with user's access token without scope" do
    setup [:create_user, :create_channel]

    setup context do
      create_token_and_return_context(context.conn, context.user, "public")
    end

    test "cannot send a chat message", %{conn: conn, channel: channel} do
      conn =
        post(conn, "/api", %{
          "query" => @create_chat_message_query,
          "variables" => %{
            channelId: "#{channel.id}",
            message: %{
              message: "Hello world"
            }
          }
        })

      assert is_nil(json_response(conn, 200)["data"]["createChatMessage"])

      assert [
               %{
                 "locations" => _,
                 "message" => "unauthorized",
                 "path" => _
               }
             ] = json_response(conn, 200)["errors"]
    end
  end

  describe "chat api with user's access token" do
    setup [:register_and_set_user_token, :create_channel]

    test "can send a chat message", %{conn: conn, user: user, channel: channel} do
      conn =
        post(conn, "/api", %{
          "query" => @create_chat_message_query,
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
               }
             }
    end

    test "can perform moderation actions", %{conn: conn, user: streamer, channel: channel} do
      user_to_ban = user_fixture()

      conn =
        post(conn, "/api", %{
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
  end

  describe "chat api with app client credentials" do
    setup [:register_and_set_user_token, :create_channel]

    test "can send a chat message", %{conn: conn, user: user, channel: channel} do
      conn =
        post(conn, "/api", %{
          "query" => @create_chat_message_query,
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
               }
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
end
