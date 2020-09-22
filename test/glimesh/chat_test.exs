defmodule Glimesh.ChatTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures
  alias Glimesh.Chat

  describe "chat_messages" do
    alias Glimesh.Chat.ChatMessage

    @valid_attrs %{message: "some message"}
    @update_attrs %{message: "some updated message"}
    @invalid_attrs %{message: nil}

    def chat_message_fixture(attrs \\ %{}) do
      channel = channel_fixture()
      user = user_fixture()

      {:ok, chat_message} =
        Chat.create_chat_message(channel, user, attrs |> Enum.into(@valid_attrs))

      chat_message
    end

    test "list_chat_messages/0 returns all chat_messages" do
      chat_message = chat_message_fixture()
      assert length(Chat.list_chat_messages(chat_message.channel)) == 1
    end

    test "get_chat_message!/1 returns the chat_message with given id" do
      chat_message = chat_message_fixture()
      assert Chat.get_chat_message!(chat_message.id).id == chat_message.id
      assert Chat.get_chat_message!(chat_message.id).message == chat_message.message
    end

    test "create_chat_message/1 with valid data creates a chat_message" do
      assert {:ok, %ChatMessage{} = chat_message} =
               Chat.create_chat_message(channel_fixture(), user_fixture(), @valid_attrs)

      assert chat_message.message == "some message"
    end

    test "create_chat_message/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Chat.create_chat_message(channel_fixture(), user_fixture(), @invalid_attrs)
    end

    #    test "delete_chat_message/1 deletes the chat_message" do
    #      chat_message = chat_message_fixture()
    #      assert {:ok, %ChatMessage{}} = Chat.delete_chat_message(chat_message)
    #      assert_raise Ecto.NoResultsError, fn -> Chat.get_chat_message!(chat_message.id) end
    #    end

    test "change_chat_message/1 returns a chat_message changeset" do
      chat_message = chat_message_fixture()
      assert %Ecto.Changeset{} = Chat.change_chat_message(chat_message)
    end
  end
end
