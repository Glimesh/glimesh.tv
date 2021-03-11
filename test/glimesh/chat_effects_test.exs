defmodule Glimesh.ChatEffectsTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures
  import Glimesh.PaymentsFixtures
  import Phoenix.HTML, only: [safe_to_string: 1]

  alias Glimesh.Chat.ChatMessage
  alias Glimesh.Chat.Effects
  alias Glimesh.StreamModeration

  describe "chat rendering" do
    setup do
      streamer = streamer_fixture()
      moderator = user_fixture()

      {:ok, _} =
        StreamModeration.create_channel_moderator(streamer, streamer.channel, moderator, %{
          can_short_timeout: true,
          can_long_timeout: true,
          can_ban: true
        })

      %{
        channel: streamer.channel,
        streamer: streamer,
        moderator: moderator,
        user: user_fixture()
      }
    end

    test "renders appropriate tags for admins", %{channel: channel} do
      admin = admin_fixture()

      assert safe_to_string(Effects.render_username(admin)) =~ "Glimesh Staff"

      assert safe_to_string(Effects.render_avatar(admin)) =~
               "avatar-ring platform-admin-ring"

      assert Effects.render_channel_badge(channel, admin) == ""
    end

    test "renders appropriate tags for moderator", %{
      channel: channel,
      moderator: moderator
    } do
      assert safe_to_string(Effects.render_channel_badge(channel, moderator)) =~
               "Mod"

      assert safe_to_string(Effects.render_channel_badge(channel, moderator)) =~
               "badge badge-primary"
    end

    test "renders appropriate tags for platform founder subscribers", %{
      user: user
    } do
      {:ok, _sub} = platform_founder_subscription_fixture(user)
      rendered_username = safe_to_string(Effects.render_username(user))
      rendered_avatar = safe_to_string(Effects.render_avatar(user))

      assert rendered_username =~ "text-warning"
      assert rendered_username =~ "Glimesh Gold Supporter Subscriber"
      assert rendered_avatar =~ "avatar-ring avatar-animated-ring platform-founder-ring"
    end

    test "renders appropriate tags for platform supporter subscribers", %{user: user} do
      {:ok, _sub} = platform_supporter_subscription_fixture(user)
      rendered_username = safe_to_string(Effects.render_username(user))
      rendered_avatar = safe_to_string(Effects.render_avatar(user))

      assert rendered_username =~ "text-color-link"
      assert rendered_username =~ "Glimesh Supporter Subscriber"
      assert rendered_avatar =~ "avatar-ring platform-supporter-ring"
    end

    test "renders appropriate tags for channel subscribers", %{
      channel: channel,
      streamer: streamer,
      user: user
    } do
      {:ok, _sub} = channel_subscription_fixture(streamer, user)

      assert safe_to_string(Effects.render_channel_badge(channel, user)) =~
               "Channel Subscriber"

      assert safe_to_string(Effects.render_channel_badge(channel, user)) =~
               "badge badge-secondary"
    end

    test "renders appropriate tags for streamer", %{channel: channel, streamer: streamer} do
      assert safe_to_string(Effects.render_channel_badge(channel, streamer)) =~
               "Streamer"

      assert safe_to_string(Effects.render_channel_badge(channel, streamer)) =~
               "badge badge-primary"
    end

    test "renders appropriate tags for regular viewer", %{user: user} do
      rendered_username = safe_to_string(Effects.render_username(user))
      rendered_avatar = safe_to_string(Effects.render_avatar(user))

      assert rendered_username =~ "text-color-link"
      assert rendered_username =~ user.displayname
      assert rendered_avatar =~ "avatar-ring"
    end

    test "user_in_message/2 doesn't trigger with no user" do
      assert Effects.user_in_message(nil, %ChatMessage{}) == false
    end

    test "user_in_message/2 detects username in message", %{
      user: user,
      streamer: streamer,
      channel: channel
    } do
      {:ok, message} =
        Glimesh.Chat.create_chat_message(streamer, channel, %{
          message: "hello #{user.username} world"
        })

      assert Effects.user_in_message(user, message)

      {:ok, message} =
        Glimesh.Chat.create_chat_message(streamer, channel, %{
          message: "hello @#{user.username} world"
        })

      assert Effects.user_in_message(user, message)
    end
  end
end
