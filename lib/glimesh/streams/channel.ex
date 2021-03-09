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
    field :mature_content, :boolean, default: false
    field :thumbnail, :string
    field :hmac_key, :string
    field :inaccessible, :boolean, default: false
    field :backend, :string
    field :disable_hyperlinks, :boolean, default: false
    field :block_links, :boolean, default: false
    field :require_confirmed_email, :boolean, default: false
    field :minimum_account_age, :integer, default: 0

    field :chat_rules_md, :string
    field :chat_rules_html, :string

    field :poster, Glimesh.ChannelPoster.Type
    field :chat_bg, Glimesh.ChatBackground.Type

    many_to_many :tags, Glimesh.Streams.Tag, join_through: "channel_tags", on_replace: :delete

    has_many :chat_messages, Glimesh.Chat.ChatMessage
    has_many :bans, Glimesh.Streams.ChannelBan
    has_many :moderators, Glimesh.Streams.ChannelModerator
    has_many :moderation_logs, Glimesh.Streams.ChannelModerationLog

    timestamps()
  end

  def create_changeset(channel, attrs \\ %{}) do
    channel
    |> changeset(attrs)
    |> put_change(:status, "offline")
    |> put_change(:hmac_key, generate_hmac_key())
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

  def hmac_key_changeset(channel) do
    channel
    |> put_change(:hmac_key, generate_hmac_key())
  end

  def changeset(channel, attrs \\ %{}) do
    channel
    |> cast(attrs, [
      :title,
      :category_id,
      :stream_id,
      :language,
      :mature_content,
      :thumbnail,
      :hmac_key,
      :chat_rules_md,
      :inaccessible,
      :status,
      :disable_hyperlinks,
      :block_links,
      :require_confirmed_email,
      :minimum_account_age
    ])
    |> validate_length(:chat_rules_md, max: 8192)
    |> validate_length(:title, max: 250)
    |> validate_number(:minimum_account_age,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 720
    )
    |> set_chat_rules_content_html()
    |> cast_attachments(attrs, [:poster, :chat_bg])
    |> maybe_put_tags(:tags, attrs)
    |> unique_constraint([:user_id])
  end

  alias Glimesh.Streams.Tag

  def tags_changeset(channel, tags) do
    channel
    |> change()
    |> put_assoc(:tags, tags)
  end

  def maybe_put_tags(changeset, key, attrs) do
    # Make sure we're not accidentally unsetting tags
    if Map.has_key?(attrs, "tags") do
      changeset |> put_assoc(key, parse_tags(attrs))
    else
      changeset
    end
  end

  def parse_tags(attrs) do
    case Jason.decode(attrs["tags"] || "[]") do
      {:ok, content} -> insert_and_get_all(content)
      _ -> insert_and_get_all([])
    end
  end

  defp insert_and_get_all([]) do
    []
  end

  defp insert_and_get_all(inputs) do
    Enum.map(inputs, fn input ->
      {:ok, tag} =
        Glimesh.ChannelCategories.upsert_tag(
          %Tag{},
          %{
            category_id: input["category_id"],
            name: input["value"]
          }
        )

      tag
    end)
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
        case Glimesh.Accounts.Profile.safe_user_markdown_to_html(chat_rules_md) do
          {:ok, content} ->
            put_change(changeset, :chat_rules_html, content)

          {:error, message} ->
            add_error(changeset, :chat_rules_html, message)
        end

      _ ->
        changeset
    end
  end

  defp generate_hmac_key do
    :crypto.strong_rand_bytes(64) |> Base.encode64() |> binary_part(0, 64)
  end
end
