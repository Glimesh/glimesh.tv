defmodule Glimesh.ChannelTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures
  alias Glimesh.Streams

  describe "stream_settings" do
    @valid_attrs %{title: "Valid Title", category_id: 2}
    @invalid_attrs %{title: nil}
    @blank_chat_rules %{chat_rules_md: ""}

    test "delete_channel/1 soft deletes channel successfully" do
      [channel, streamer] = channel_streamer_fixture()
      {:ok, channel} = Streams.delete_channel(streamer, channel)
      assert channel.inaccessible == true
    end

    test "update_channel/2 with valid data updates the channel" do
      [channel, streamer] = channel_streamer_fixture()
      assert channel.title == "Live Stream!"
      assert channel.category_id == 1
      {:ok, channel} = Streams.update_channel(streamer, channel, @valid_attrs)
      assert channel.title == "Valid Title"
      assert channel.category_id == 2
    end

    test "update_channel/2 with invalid data defaults to default values" do
      [channel, streamer] = channel_streamer_fixture()
      {:ok, channel} = Streams.update_channel(streamer, channel, @invalid_attrs)
      assert channel.title == nil
    end

    test "update_channel/2 with blank chat rules defaults to nil" do
      [channel, streamer] = channel_streamer_fixture()
      {:ok, channel} = Streams.update_channel(streamer, channel, %{chat_rules_md: "Test rules"})
      assert channel.chat_rules_html =~ "<p>\nTest rules</p>\n"
      {:ok, channel} = Streams.update_channel(streamer, channel, @blank_chat_rules)
      assert channel.chat_rules_html == nil
    end
  end
end
