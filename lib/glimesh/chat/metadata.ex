defmodule Glimesh.Chat.ChatMessage.Metadata do
  use Ecto.Schema

  embedded_schema do
    field(:streamer, :boolean)
    field(:subscriber, :boolean)
    field(:mod, :boolean)
    field(:admin, :boolean)
  end

  def defaults() do
    %{
      streamer: false,
      subscriber: false,
      moderator: false,
      admin: false
    }
  end
end
