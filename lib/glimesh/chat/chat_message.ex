defmodule Glimesh.Chat.ChatMessage do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Glimesh.Accounts.User
  alias Glimesh.Streams.Channel

  schema "chat_messages" do
    field :message, :string
    field :is_visible, :boolean, default: true
    field :is_followed_message, :boolean, default: false

    embeds_many :tokens, Glimesh.Chat.Token, on_replace: :delete

    belongs_to :channel, Channel
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(chat_message, attrs) do
    chat_message
    |> cast(attrs, [:message, :is_visible, :is_followed_message])
    |> validate_required([:channel, :user, :message])
  end

  def put_tokens(changeset, config) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{message: message}} ->
        tokens = Glimesh.Chat.Parser.parse(message, config)
        put_embed(changeset, :tokens, tokens)

      _ ->
        changeset
    end
  end

  @doc false
  def token_changeset(chat_message, tokens \\ []) do
    chat_message
    |> put_embed(:tokens, tokens)
  end
end
