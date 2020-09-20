defmodule Glimesh.Chat.ChatMessage do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Glimesh.Accounts.User

  schema "chat_messages" do
    belongs_to :streamer, User
    belongs_to :user, User
    field :message, :string
    field :is_visible, :boolean, default: true

    timestamps()
  end

  @doc false
  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [:message, :is_visible])
    |> validate_required([:streamer, :user, :message])
    |> validate_length(:message, max: 250)
  end
end
