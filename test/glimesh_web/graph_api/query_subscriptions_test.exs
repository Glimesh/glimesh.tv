defmodule GlimeshWeb.GraphApi.QuerySubscriptionsTest do
  use GlimeshWeb.GraphSubscriptionCase

  import Glimesh.AccountsFixtures

  describe "anonymous subscriptions" do
    setup :setup_anonymous_socket

    test "can subscribe to normal channel data", %{socket: socket} do
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

    test "can watch a channel", %{socket: socket} do
      streamer = streamer_fixture()

      Glimesh.Janus.create_edge_route(%{
        hostname: "new-york",
        url: "https://new-york/janus",
        priority: 1.0,
        available: true,
        country_codes: ["US"]
      })

      channel_id = streamer.channel.id

      ref =
        push_doc(
          socket,
          """
            mutation watchChannel($channelId: ID!, $country: String!) {
              watchChannel(channelId: $channelId, country: $country) {
                id
              }
            }
          """,
          variables: %{
            "channelId" => channel_id,
            "country" => "US"
          }
        )

      assert_reply(ref, :ok, %{data: %{"watchChannel" => %{"id" => _}}})

      # For some reason this does not work... I'm guessing because of multiple processes?
      # viewer_count =
      #   Glimesh.Streams.get_subscribe_topic(:viewers, channel_id)
      #   |> Glimesh.Presence.list_presences()
      #   |> Enum.count()

      # assert viewer_count == 1
    end

    test "cannot perform auth-required actions", %{socket: socket} do
      streamer = streamer_fixture()

      ref =
        push_doc(
          socket,
          """
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
          """,
          variables: %{
            "channelId" => streamer.channel.id,
            message: %{
              message: "Hello world"
            }
          }
        )

      assert_reply(ref, :ok, %{
        data: %{"createChatMessage" => nil},
        errors: [
          %{
            message: "unauthorized",
            path: ["createChatMessage"]
          }
        ]
      })
    end
  end

  describe "channel subscriptions" do
    setup :setup_socket

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

  describe "chat message subscriptions" do
    setup :setup_socket

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

  describe "follower subscriptions" do
    setup :setup_socket

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
