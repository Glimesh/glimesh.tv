defmodule Glimesh.ApiNext.SubscriptionTest do
  use GlimeshWeb.SubscriptionCaseApiNext

  import Glimesh.AccountsFixtures

  describe "channel subscriptions apinew" do
    setup :setup_socket_apinext

    test "updating channel title sends subscription update", %{socket: socket} do
      streamer = streamer_fixture()

      ref =
        push_doc(
          socket,
          """
            subscription channel($channelId: ID!) {
              channel(id: $channelId) {
                title
              }
            }
          """,
          variables: %{
            "channelId" => streamer.channel.id
          }
        )

      assert_reply(ref, :ok, %{subscriptionId: subscription_id})

      Glimesh.Streams.update_channel(streamer, streamer.channel, %{
        title: "This is changed"
      })

      assert_push("subscription:data", push)

      assert push == %{
               result: %{
                 data: %{
                   "channel" => %{"title" => "This is changed"}
                 }
               },
               subscriptionId: subscription_id
             }
    end

    test "channel firehose subscription works", %{socket: socket} do
      streamer = streamer_fixture()

      ref =
        push_doc(socket, """
          subscription channel{
            channel {
              id
              title
            }
          }
        """)

      assert_reply(ref, :ok, %{subscriptionId: subscription_id})

      Glimesh.Streams.update_channel(streamer, streamer.channel, %{
        title: "This is changed"
      })

      assert_push("subscription:data", push)

      assert push == %{
               result: %{
                 data: %{
                   "channel" => %{"id" => "#{streamer.channel.id}", "title" => "This is changed"}
                 }
               },
               subscriptionId: subscription_id
             }
    end
  end

  describe "chat message subscriptions apinew" do
    setup :setup_socket_apinext

    test "sending a chat message updates subscription", %{socket: socket, user: user} do
      streamer = streamer_fixture()

      ref =
        push_doc(
          socket,
          """
            subscription chatMessage($channelId: ID!) {
              chatMessage(channelId: $channelId) {
                message
                user {
                  username
                }
              }
            }
          """,
          variables: %{
            "channelId" => streamer.channel.id
          }
        )

      assert_reply(ref, :ok, %{subscriptionId: subscription_id})

      Glimesh.Chat.create_chat_message(user, streamer.channel, %{
        "message" => "Hello world"
      })

      assert_push("subscription:data", push)

      assert push == %{
               result: %{
                 data: %{
                   "chatMessage" => %{
                     "message" => "Hello world",
                     "user" => %{"username" => user.username}
                   }
                 }
               },
               subscriptionId: subscription_id
             }
    end

    test "chat message firehose subscription works", %{socket: socket, user: user} do
      streamer = streamer_fixture()

      ref =
        push_doc(socket, """
        subscription chatMessage {
          chatMessage {
            message
            user {
              username
            }
            channel {
              id
            }
          }
        }
        """)

      assert_reply(ref, :ok, %{subscriptionId: subscription_id})

      Glimesh.Chat.create_chat_message(user, streamer.channel, %{
        "message" => "Hello world"
      })

      assert_push("subscription:data", push)

      assert push == %{
               result: %{
                 data: %{
                   "chatMessage" => %{
                     "message" => "Hello world",
                     "user" => %{"username" => user.username},
                     "channel" => %{"id" => "#{streamer.channel.id}"}
                   }
                 }
               },
               subscriptionId: subscription_id
             }
    end
  end

  describe "followers apinew" do
    setup :setup_socket_apinext

    test "following subcription works", %{socket: socket, user: user} do
      streamer = streamer_fixture()

      ref =
        push_doc(
          socket,
          """
            subscription followers($streamerId: ID!) {
              followers(streamerId: $streamerId) {
                user {
                  username
                }
              }
            }
          """,
          variables: %{
            "streamerId" => streamer.id
          }
        )

      assert_reply(ref, :ok, %{subscriptionId: subscription_id})

      Glimesh.AccountFollows.follow(streamer, user)

      assert_push("subscription:data", push)

      assert push == %{
               result: %{
                 data: %{
                   "followers" => %{"user" => %{"username" => user.username}}
                 }
               },
               subscriptionId: subscription_id
             }
    end

    test "following firehose works", %{socket: socket, user: user} do
      streamer = streamer_fixture()

      ref =
        push_doc(socket, """
          subscription followers {
            followers {
              user {
                username
              }
            }
          }
        """)

      assert_reply(ref, :ok, %{subscriptionId: subscription_id})

      Glimesh.AccountFollows.follow(streamer, user)

      assert_push("subscription:data", push)

      assert push == %{
               result: %{
                 data: %{
                   "followers" => %{"user" => %{"username" => user.username}}
                 }
               },
               subscriptionId: subscription_id
             }
    end
  end
end
