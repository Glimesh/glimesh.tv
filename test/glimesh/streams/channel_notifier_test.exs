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
  end
end
