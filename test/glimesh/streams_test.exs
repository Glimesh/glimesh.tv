defmodule Glimesh.StreamsTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures
  alias Glimesh.Streams
  alias Glimesh.ChannelLookups

  describe "followers" do
    def followers_fixture do
      streamer = streamer_fixture()
      user = user_fixture()

      {:ok, followers} = Streams.follow(streamer, user)

      followers
    end

    test "follow/2 successfully follows streamer" do
      streamer = streamer_fixture()
      user = user_fixture()
      Streams.follow(streamer, user)

      followed = ChannelLookups.list_all_followed_channels(user)

      assert Enum.map(followed, fn x -> x.user.username end) == [streamer.username]
    end

    test "unfollow/2 successfully unfollows streamer" do
      streamer = streamer_fixture()
      user = user_fixture()
      Streams.follow(streamer, user)
      followed = ChannelLookups.list_all_followed_channels(user)

      assert Enum.map(followed, fn x -> x.user.username end) == [streamer.username]

      Streams.unfollow(streamer, user)
      assert ChannelLookups.list_all_followed_channels(user) == []
    end

    test "is_following?/1 detects active follow" do
      streamer = streamer_fixture()
      user = user_fixture()
      Streams.follow(streamer, user)
      assert Streams.is_following?(streamer, user) == true
    end

    test "follow/2 twice returns error changeset" do
      streamer = streamer_fixture()
      user = user_fixture()

      Streams.follow(streamer, user)
      assert {:error, %Ecto.Changeset{}} = Streams.follow(streamer, user)
    end
  end

  describe "channels" do
    setup do
      streamer = streamer_fixture()
      {:ok, channel: streamer.channel, streamer: streamer}
    end

    test "rotate_stream_key/1 changes a stream key", %{channel: channel, streamer: streamer} do
      {:ok, new_channel} = Streams.rotate_stream_key(streamer, channel)
      assert new_channel.stream_key != channel.stream_key
    end
  end

  describe "ingest stream api" do
    setup do
      %{channel: channel} = streamer_fixture()

      {:ok, channel: channel}
    end

    test "start_stream/1 successfully starts a stream", %{channel: channel} do
      {:ok, stream} = Streams.start_stream(channel)
      new_channel = ChannelLookups.get_channel!(channel.id)

      assert stream.started_at != nil
      assert stream.ended_at == nil
      assert stream.id == new_channel.stream_id
      assert stream.category_id == new_channel.category_id
      assert new_channel.status == "live"
    end

    test "start_stream/1 stops any other streams that still are lingering", %{channel: channel} do
      %Glimesh.Streams.Stream{channel: channel}
      |> Glimesh.Streams.Stream.changeset(%{})
      |> Glimesh.Repo.insert()

      %Glimesh.Streams.Stream{channel: channel}
      |> Glimesh.Streams.Stream.changeset(%{})
      |> Glimesh.Repo.insert()

      {:ok, _} = Streams.start_stream(channel)

      assert Repo.one(
               from s in Glimesh.Streams.Stream,
                 where: s.channel_id == ^channel.id and is_nil(s.ended_at),
                 select: count(s.id)
             ) == 1
    end

    test "end_stream/1 successfully stops a stream", %{channel: channel} do
      {:ok, _} = Streams.start_stream(channel)
      fresh_channel = ChannelLookups.get_channel!(channel.id)
      {:ok, stream} = Streams.end_stream(fresh_channel)
      new_channel = ChannelLookups.get_channel!(channel.id)

      assert stream.started_at != nil
      assert stream.ended_at != nil
      assert new_channel.status == "offline"
      assert new_channel.stream_id == nil
    end

    test "end_stream/1 successfully stops a stream with stream", %{channel: channel} do
      {:ok, stream} = Streams.start_stream(channel)
      {:ok, stream} = Streams.end_stream(stream)
      new_channel = ChannelLookups.get_channel!(channel.id)

      assert stream.started_at != nil
      assert stream.ended_at != nil
      assert new_channel.status == "offline"
      assert new_channel.stream_id == nil
    end

    test "log_stream_metadata/1 successfully logs some metadata", %{channel: channel} do
      {:ok, stream} = Streams.start_stream(channel)

      incoming_attrs = %{
        audio_codec: "mp3",
        ingest_server: "test",
        ingest_viewers: 32,
        stream_time_seconds: 1024,
        lost_packets: 0,
        nack_packets: 0,
        recv_packets: 100,
        source_bitrate: 5000,
        source_ping: 100,
        vendor_name: "OBS",
        vendor_version: "1.0.0",
        video_codec: "mp4",
        video_height: 1024,
        video_width: 768
      }

      assert {:ok, %{}} = Streams.log_stream_metadata(stream, incoming_attrs)
    end
  end
end
