defmodule Glimesh.Chat.ChatMessage do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Glimesh.Accounts.User
  alias Glimesh.Chat.ChatMessage.Metadata
  alias Glimesh.Streams.Channel

  schema "chat_messages" do
    field :message, :string
    field :is_visible, :boolean, default: true
    field :is_followed_message, :boolean, default: false
    field :is_subscription_message, :boolean, default: false
    field :is_raid_message, :boolean, default: false

    embeds_one :metadata, Metadata, on_replace: :update
    embeds_many :tokens, Glimesh.Chat.Token, on_replace: :delete

    belongs_to :channel, Channel
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [
      :message,
      :is_visible,
      :is_followed_message,
      :is_subscription_message,
      :is_raid_message
    ])
    |> cast_embed(:metadata)
    |> validate_required([:channel, :user, :message])
    |> validate_length(:message, min: 1, max: 255)
  end

  @doc false
  def put_tokens(changeset, config) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{message: message}} ->
        tokens = Glimesh.Chat.Parser.parse(message, config)
        put_embed(changeset, :tokens, tokens)

      _ ->
        changeset
    end
  end
end
