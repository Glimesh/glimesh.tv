defmodule Glimesh.Chat.ChatMessage do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Glimesh.Accounts.User
  alias Glimesh.Streams.Channel

  schema "chat_messages" do
    field :message, :string
    field :is_visible, :boolean, default: true

    belongs_to :channel, Channel
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [:message, :is_visible])
    |> validate_required([:channel, :user, :message])
  end
end
