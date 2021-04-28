defmodule Glimesh.Chat.MetadataTest do
  use Glimesh.DataCase
  import Glimesh.Factory
  alias Glimesh.Chat.ChatMessage.Metadata

  test "old chat messages have a nil value" do
    message = insert(:chat_message, metadata: nil)
    assert message.metadata == nil
  end

  test "chat messages have metadata when assigned" do
    message = insert(:chat_message, metadata: Metadata.defaults())
    assert message.metadata.streamer == false
    assert message.metadata.moderator == false
  end

  test "chat messages have metadata when values are changed" do
    metadata = Metadata.defaults() |> Map.put(:streamer, true)
    message = insert(:chat_message, metadata: metadata)
    assert message.metadata.streamer == true
    assert message.metadata.moderator == false
  end
end
