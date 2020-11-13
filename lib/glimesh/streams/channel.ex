defmodule Glimesh.Streams.Channel do
  @moduledoc false
  use Ecto.Schema
  use Waffle.Ecto.Schema

  import Ecto.Changeset

  schema "channels" do
    belongs_to :user, Glimesh.Accounts.User
    belongs_to :category, Glimesh.Streams.Category
    belongs_to :streamer, Glimesh.Accounts.User, source: :user_id
    belongs_to :stream, Glimesh.Streams.Stream
    has_many :streams, Glimesh.Streams.Stream

    field :title, :string, default: "Live Stream!"
    field :status, :string
    field :language, :string
    field :thumbnail, :string
    field :stream_key, :string
    field :inaccessible, :boolean, default: false
    field :backend, :string
    field :disable_hyperlinks, :boolean, default: false
    field :block_links, :boolean, default: false

    field :chat_rules_md, :string
    field :chat_rules_html, :string

    field :poster, Glimesh.ChannelPoster.Type
    field :chat_bg, Glimesh.ChatBackground.Type

    has_many :chat_messages, Glimesh.Chat.ChatMessage

    timestamps()
  end

  def create_changeset(channel, attrs \\ %{}) do
    channel
    |> changeset(attrs)
    |> put_change(:status, "offline")
    |> put_change(:stream_key, generate_stream_key())
  end

  def start_changeset(channel, attrs \\ %{}) do
    channel
    |> changeset(attrs)
    |> put_change(:status, "live")
  end

  def stop_changeset(channel, attrs \\ %{}) do
    channel
    |> changeset(attrs)
    |> put_change(:stream_id, nil)
    |> put_change(:status, "offline")
  end

  def stream_key_changeset(channel) do
    channel
    |> put_change(:stream_key, generate_stream_key())
  end

  def changeset(channel, attrs \\ %{}) do
    channel
    |> cast(attrs, [
      :title,
      :category_id,
      :stream_id,
      :language,
      :thumbnail,
      :stream_key,
      :chat_rules_md,
      :inaccessible,
      :status,
      :disable_hyperlinks,
      :block_links
    ])
    |> validate_length(:chat_rules_md, max: 8192)
    |> set_chat_rules_content_html()
    |> cast_attachments(attrs, [:poster, :chat_bg])
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

  defp generate_stream_key do
    :crypto.strong_rand_bytes(64) |> Base.encode64() |> binary_part(0, 64)
  end
end
