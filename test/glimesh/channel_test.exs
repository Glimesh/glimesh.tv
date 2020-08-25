defmodule Glimesh.ChannelTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures
  alias Glimesh.Streams

  describe "stream_settings" do
    alias Glimesh.Streams.Channel

    @valid_attrs %{title: "Valid Title", category_id: 2}
    @invalid_attrs %{title: nil}

    def channel_fixture(attrs \\ %{category_id: 1}) do
      streamer = streamer_fixture()
      channel = Streams.get_channel_for_username!(streamer.username)
    end

    test "delete_channel/1 soft deletes channel successfully" do
      channel = channel_fixture()
      {:ok, channel} = Streams.delete_channel(channel)
      assert channel.inaccessible == true
    end

    test "update_channel/2 with valid data updates the channel" do
      channel = channel_fixture()
      assert channel.title == "Live Stream!"
      assert channel.category_id == 1
      {:ok, channel} = Streams.update_channel(channel, @valid_attrs)
      assert channel.title == "Valid Title"
      assert channel.category_id == 2
    end

    test "update_channel/2 with invalid data defaults to default values" do
      channel = channel_fixture()
      {:ok, channel} = Streams.update_channel(channel, @invalid_attrs)
      assert channel.title == nil
    end
  end
end
