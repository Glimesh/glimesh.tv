defmodule Glimesh.StreamsTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures
  alias Glimesh.Chat
  alias Glimesh.Streams
  alias Glimesh.Streams.UserModerationLog

  describe "timeout_user/3" do
    setup do
      %{
        streamer: user_fixture(),
        moderator: user_fixture(),
        user: user_fixture()
      }
    end

    test "times out a user and removes messages successfully", %{
      streamer: streamer,
      moderator: moderator,
      user: user
    } do
      {:ok, _} = Chat.create_chat_message(streamer, user, %{message: "bad message"})
      {:ok, _} = Chat.create_chat_message(streamer, moderator, %{message: "good message"})
      assert length(Chat.list_chat_messages(streamer)) == 2

      {:ok, _} = Glimesh.Streams.add_moderator(streamer, moderator)

      {:ok, _} = Streams.timeout_user(streamer, moderator, user)
      assert length(Chat.list_chat_messages(streamer)) == 1
    end

    test "adds log of timeout action", %{streamer: streamer, moderator: moderator, user: user} do
      {:ok, _} = Glimesh.Streams.add_moderator(streamer, moderator)
      {:ok, record} = Streams.timeout_user(streamer, moderator, user)

      assert record.streamer.id == streamer.id
      assert record.moderator.id == moderator.id
      assert record.user.id == user.id
      assert record.action == "timeout"
    end

    test "moderation privileges are required to timeout", %{
      streamer: streamer,
      moderator: moderator,
      user: user
    } do
      assert_raise RuntimeError,
                   "User does not have permission to moderate.",
                   fn -> Streams.timeout_user(streamer, moderator, user) end
    end
  end

  describe "followers" do
    alias Glimesh.Streams.Followers

    @valid_attrs %{has_live_notifications: true}
    @update_attrs %{has_live_notifications: false}
    @invalid_attrs %{has_live_notifications: nil}

    def followers_fixture do
      streamer = user_fixture()
      user = user_fixture()

      {:ok, followers} = Streams.follow(streamer, user)

      followers
    end

    test "follow/2 successfully follows streamer" do
      streamer = user_fixture()
      user = user_fixture()
      Streams.follow(streamer, user)
      assert Streams.list_followed_streams(user) == [streamer]
    end

    test "unfollow/2 successfully unfollows streamer" do
      streamer = user_fixture()
      user = user_fixture()
      Streams.follow(streamer, user)
      assert Streams.list_followed_streams(user) == [streamer]

      Streams.unfollow(streamer, user)
      assert Streams.list_followed_streams(user) == []
    end

    test "is_following?/1 detects active follow" do
      streamer = user_fixture()
      user = user_fixture()
      Streams.follow(streamer, user)
      assert Streams.is_following?(streamer, user) == true
    end

    test "follow/2 twice returns error changeset" do
      streamer = user_fixture()
      user = user_fixture()

      Streams.follow(streamer, user)
      assert {:error, %Ecto.Changeset{}} = Streams.follow(streamer, user)
    end
  end
end
