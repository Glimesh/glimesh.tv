defmodule Glimesh.Chat.ChatMessage.Metadata do
  @moduledoc """
  Embeddable Schema for storing stateful metadata
  about a chat message
  """

  use Ecto.Schema

  embedded_schema do
    field :streamer, :boolean
    field :subscriber, :boolean
    field :moderator, :boolean
    field :admin, :boolean
    field :platform_founder_subscriber, :boolean
    field :platform_supporter_subscriber, :boolean
  end

  def defaults do
    %{
      streamer: false,
      subscriber: false,
      moderator: false,
      admin: false,
      platform_founder_subscriber: false,
      platform_supporter_subscriber: false
    }
  end
end
