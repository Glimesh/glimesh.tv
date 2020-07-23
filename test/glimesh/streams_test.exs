defmodule Glimesh.StreamsTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures
  alias Glimesh.Streams
  alias Glimesh.Chat
  alias Glimesh.Streams.{UserModerationLog}

  describe "timeout_user/3" do
    setup do
      %{
        streamer: user_fixture(),
        moderator: user_fixture(),
        user: user_fixture(),
      }
    end

    test "times out a user and removes messages successfully", %{streamer: streamer, moderator: moderator, user: user} do
      {:ok, _} = Chat.create_chat_message(streamer, user, %{message: "bad message"})
      {:ok, _} = Chat.create_chat_message(streamer, moderator, %{message: "good message"})
      assert length(Chat.list_chat_messages(streamer)) == 2

      {:ok, _} = Streams.timeout_user(streamer, moderator, user)
      assert length(Chat.list_chat_messages(streamer)) == 1
    end

    test "adds log of timeout action", %{streamer: streamer, moderator: moderator, user: user} do
      {:ok, record} = Streams.timeout_user(streamer, moderator, user)

      assert record.streamer.id == streamer.id
      assert record.moderator.id == moderator.id
      assert record.user.id == user.id
      assert record.action == "timeout"
    end
    #
    #    test "returns the user if the email exists" do
    ##      %{id: id} = user = user_fixture()
    ##      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    #    end
  end

end
