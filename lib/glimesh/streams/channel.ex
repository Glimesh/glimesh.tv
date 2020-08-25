defmodule Glimesh.Streams.Channel do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "channels" do
    belongs_to :user, Glimesh.Accounts.User
    belongs_to :category, Glimesh.Streams.Category

    field :title, :string, default: "Live Stream!"
    field :status, :string
    field :language, :string
    field :thumbnail, :string
    field :stream_key, :string
    field :inaccessible, :boolean, default: false

    field :chat_rules_md, :string
    field :chat_rules_html, :string
    timestamps()
  end

  def changeset(channel, attrs \\ %{}) do
    channel
    |> cast(attrs, [:title, :category_id, :language, :thumbnail, :stream_key, :chat_rules_md, :inaccessible])
    |> validate_length(:chat_rules_md, max: 8192)
    |> validate_length(:title, max: 50)
    |> set_chat_rules_content_html()
  end

  def maybe_put_assoc(changeset, key, value) do
    if value do
      changeset |> put_assoc(key, value)
    else
      changeset
    end
  end

  def set_chat_rules_content_html(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{chat_rules_md: chat_rules_md}} ->
        put_change(
          changeset,
          :chat_rules_html,
          Glimesh.Accounts.Profile.safe_user_markdown_to_html(chat_rules_md)
        )

      _ ->
        changeset
    end
  end
end
