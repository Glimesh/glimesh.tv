defmodule Glimesh.Chat.ChatMessage.Metadata do
  @moduledoc """
  Embeddable Schema for storing stateful metadata
  about a chat message
  """

  use Ecto.Schema

  embedded_schema do
    field(:streamer, :boolean)
    field(:subscriber, :boolean)
    field(:moderator, :boolean)
    field(:admin, :boolean)
  end

  def defaults do
    %{
      streamer: false,
      subscriber: false,
      moderator: false,
      admin: false
    }
  end
end
