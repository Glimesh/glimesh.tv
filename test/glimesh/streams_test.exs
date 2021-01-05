defmodule Glimesh.StreamsTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures
  alias Glimesh.Streams

  describe "followers" do
    @valid_attrs %{has_live_notifications: true}
    @update_attrs %{has_live_notifications: false}
    @invalid_attrs %{has_live_notifications: nil}

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

      followed = Streams.list_all_followed_channels(user)

      assert Enum.map(followed, fn x -> x.user.username end) == [streamer.username]
    end

    test "unfollow/2 successfully unfollows streamer" do
      streamer = streamer_fixture()
      user = user_fixture()
      Streams.follow(streamer, user)
      followed = Streams.list_all_followed_channels(user)

      assert Enum.map(followed, fn x -> x.user.username end) == [streamer.username]

      Streams.unfollow(streamer, user)
      assert Streams.list_all_followed_channels(user) == []
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

  describe "categories" do
    alias Glimesh.Streams.Category

    @valid_attrs %{
      name: "some name"
    }
    @update_attrs %{
      name: "some updated name"
    }
    @invalid_attrs %{name: nil}

    def category_fixture(attrs \\ %{}) do
      {:ok, category} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Streams.create_category()

      category
    end

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Enum.member?(Enum.map(Streams.list_categories(), fn x -> x.name end), category.name)
    end

    test "get_category_by_id!/1 returns the category with given id" do
      category = category_fixture()
      assert Streams.get_category_by_id!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      assert {:ok, %Category{} = category} = Streams.create_category(@valid_attrs)
      assert category.name == "some name"
      assert category.slug == "some-name"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Streams.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      assert {:ok, %Category{} = category} = Streams.update_category(category, @update_attrs)
      assert category.name == "some updated name"
      assert category.slug == "some-updated-name"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Streams.update_category(category, @invalid_attrs)
      assert category == Streams.get_category_by_id!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Streams.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Streams.get_category_by_id!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Streams.change_category(category)
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
      new_channel = Streams.get_channel!(channel.id)

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
      fresh_channel = Streams.get_channel!(channel.id)
      {:ok, stream} = Streams.end_stream(fresh_channel)
      new_channel = Streams.get_channel!(channel.id)

      assert stream.started_at != nil
      assert stream.ended_at != nil
      assert new_channel.status == "offline"
      assert new_channel.stream_id == nil
    end

    test "end_stream/1 successfully stops a stream with stream", %{channel: channel} do
      {:ok, stream} = Streams.start_stream(channel)
      {:ok, stream} = Streams.end_stream(stream)
      new_channel = Streams.get_channel!(channel.id)

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
