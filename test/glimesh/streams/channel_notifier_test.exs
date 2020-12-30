defmodule Glimesh.Streams.ChannelNotifierTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures

  describe "channel_notifier" do
    test "deliver_live_channel_notifications/2 delivers email for the right users" do
      streamer = streamer_fixture()
      user1 = user_fixture()
      user2 = user_fixture()

      Glimesh.Streams.follow(streamer, user1, true)
      Glimesh.Streams.follow(streamer, user2, false)

      {:ok, stream} = Glimesh.Streams.start_stream(streamer.channel)

      assert_delivered_email(
        GlimeshWeb.Emails.Email.channel_live(
          user1,
          streamer,
          streamer.channel,
          stream
        )
      )

      refute_delivered_email(
        GlimeshWeb.Emails.Email.channel_live(
          user2,
          streamer,
          streamer.channel,
          stream
        )
      )
    end

    test "deliver_live_channel_notifications/2 wont spam users for the same channel" do
      streamer = streamer_fixture()
      user = user_fixture()
      Glimesh.Streams.follow(streamer, user, true)

      {:ok, stream} = Glimesh.Streams.start_stream(streamer.channel)

      assert_delivered_email(
        GlimeshWeb.Emails.Email.channel_live(
          user,
          streamer,
          streamer.channel,
          stream
        )
      )

      {:ok, _} = Glimesh.Streams.start_stream(streamer.channel)

      assert_no_emails_delivered()
    end

    test "deliver_live_channel_notifications/2 wont send more than 5 emails to a user" do
      user = user_fixture()

      Enum.map(1..5, fn _ ->
        streamer = streamer_fixture()
        Glimesh.Streams.follow(streamer, user, true)
        {:ok, stream} = Glimesh.Streams.start_stream(streamer.channel)

        assert_delivered_email(
          GlimeshWeb.Emails.Email.channel_live(
            user,
            streamer,
            streamer.channel,
            stream
          )
        )
      end)

      streamer = streamer_fixture()
      Glimesh.Streams.follow(streamer, user, true)
      {:ok, _} = Glimesh.Streams.start_stream(streamer.channel)

      assert_no_emails_delivered()
    end

    # test "update_channel/2 with valid data updates the channel" do
    #   [channel, streamer] = channel_streamer_fixture()
    #   assert channel.title == "Live Stream!"
    #   assert channel.category_id == 1
    #   {:ok, channel} = Streams.update_channel(streamer, channel, @valid_attrs)
    #   assert channel.title == "Valid Title"
    #   assert channel.category_id == 2
    # end

    # test "update_channel/2 with invalid data defaults to default values" do
    #   [channel, streamer] = channel_streamer_fixture()
    #   {:ok, channel} = Streams.update_channel(streamer, channel, @invalid_attrs)
    #   assert channel.title == nil
    # end

    # test "update_channel/2 with blank chat rules defaults to nil" do
    #   [channel, streamer] = channel_streamer_fixture()
    #   {:ok, channel} = Streams.update_channel(streamer, channel, %{chat_rules_md: "Test rules"})
    #   assert channel.chat_rules_html =~ "<p>\nTest rules</p>\n"
    #   {:ok, channel} = Streams.update_channel(streamer, channel, @blank_chat_rules)
    #   assert channel.chat_rules_html == nil
    # end
  end
end
