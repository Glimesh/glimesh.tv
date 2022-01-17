defmodule Glimesh.ChatEffectsTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures
  import Glimesh.PaymentsFixtures
  import Phoenix.HTML, only: [safe_to_string: 1]
  import Glimesh.Factory

  alias Glimesh.Chat.ChatMessage
  alias Glimesh.Chat.Effects
  alias Glimesh.StreamModeration

  describe "chat rendering with metadata" do
    test "rendering channel badge for admin" do
      message = insert(:chat_message, metadata: %{admin: true})
      assert message |> Effects.render_channel_badge() == ""
    end

    test "rendering channel badge for streamer" do
      message = insert(:chat_message, metadata: %{streamer: true})
      assert message |> Effects.render_channel_badge() |> safe_to_string =~ "Streamer"
    end

    test "rendering channel badge for moderator" do
      message = insert(:chat_message, metadata: %{moderator: true})
      assert message |> Effects.render_channel_badge() |> safe_to_string =~ "Mod"
    end

    test "rendering channel badge for moderator with subscription" do
      message = insert(:chat_message, metadata: %{moderator: true, subscriber: true})
      assert message |> Effects.render_channel_badge() |> inspect =~ "Mod"
      assert message |> Effects.render_channel_badge() |> inspect =~ "Channel Subscriber"
    end

    test "rendering channel badge for user with subscription" do
      message = insert(:chat_message, metadata: %{subscriber: true})
      assert message |> Effects.render_channel_badge() |> inspect =~ "Channel Subscriber"
    end

    test "rendering channel badge for nil metadata returns nil" do
      message = insert(:chat_message, metadata: nil)
      assert message |> Effects.render_channel_badge() == nil
    end

    test "rendering channel badge for unmatched returns nil" do
      message = insert(:chat_message, metadata: %{})
      assert message |> Effects.render_channel_badge() == nil
    end
  end

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
      message = mock_message(admin)

      assert safe_to_string(Effects.render_username(message)) =~ "Glimesh Staff"

      assert safe_to_string(Effects.render_avatar(message)) =~
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
      message = mock_message(user)
      rendered_username = safe_to_string(Effects.render_username(message))
      rendered_avatar = safe_to_string(Effects.render_avatar(message))

      assert rendered_username =~ "text-warning"
      assert rendered_username =~ "Glimesh Gold Supporter Subscriber"
      assert rendered_avatar =~ "avatar-ring avatar-animated-ring platform-founder-ring"
    end

    test "renders appropriate tags for platform supporter subscribers", %{user: user} do
      {:ok, _sub} = platform_supporter_subscription_fixture(user)
      message = mock_message(user)
      rendered_username = safe_to_string(Effects.render_username(message))
      rendered_avatar = safe_to_string(Effects.render_avatar(message))

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
      message = mock_message(user)
      rendered_username = safe_to_string(Effects.render_username(message))
      rendered_avatar = safe_to_string(Effects.render_avatar(message))

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

  defp mock_message(user) do
    metadata =
      Map.merge(Glimesh.Chat.ChatMessage.Metadata.defaults(), %{
        platform_founder_subscriber: Glimesh.Payments.is_platform_founder_subscriber?(user),
        platform_supporter_subscriber: Glimesh.Payments.is_platform_supporter_subscriber?(user)
      })

    %Glimesh.Chat.ChatMessage{
      user: user,
      metadata: metadata
    }
  end
end
