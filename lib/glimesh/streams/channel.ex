defmodule Glimesh.Streams.Channel do
  @moduledoc false
  use Ecto.Schema
  use Waffle.Ecto.Schema

  import Ecto.Changeset

  schema "channels" do
    belongs_to :user, Glimesh.Accounts.User
    belongs_to :category, Glimesh.Streams.Category
    belongs_to :subcategory, Glimesh.Streams.Subcategory, on_replace: :nilify
    belongs_to :streamer, Glimesh.Accounts.User, source: :user_id
    belongs_to :stream, Glimesh.Streams.Stream
    has_many :streams, Glimesh.Streams.Stream

    field :title, :string, default: "Live Stream!"
    field :status, :string
    field :language, :string
    field :mature_content, :boolean, default: false
    field :show_on_homepage, :boolean, default: false
    field :thumbnail, :string
    field :hmac_key, :string
    field :inaccessible, :boolean, default: false
    field :backend, :string
    field :disable_hyperlinks, :boolean, default: false
    field :block_links, :boolean, default: false
    field :require_confirmed_email, :boolean, default: false
    field :minimum_account_age, :integer, default: 0

    field :show_recent_chat_messages_only, :boolean, default: false

    field :chat_rules_md, :string
    field :chat_rules_html, :string

    field :emote_prefix, :string

    field :allow_hosting, :boolean, default: false

    # This is here temporarily as we add additional schema to handle it.
    field :streamloots_url, :string, default: nil

    field :show_subscribe_button, :boolean, default: true
    field :show_donate_button, :boolean, default: true
    field :show_streamloots_button, :boolean, default: true

    field :poster, Glimesh.ChannelPoster.Type
    field :chat_bg, Glimesh.ChatBackground.Type

    field :show_viewer_count, :boolean, default: true

    # This is used when searching for live channels that are live or hosted
    field :match_type, :string, virtual: true

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
    |> force_change(:status, "live")
  end

  def stop_changeset(channel, attrs \\ %{}) do
    channel
    |> changeset(attrs)
    |> force_change(:stream_id, nil)
    |> force_change(:status, "offline")
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
      :subcategory_id,
      :stream_id,
      :language,
      :mature_content,
      :show_on_homepage,
      :thumbnail,
      :hmac_key,
      :chat_rules_md,
      :inaccessible,
      :status,
      :show_recent_chat_messages_only,
      :disable_hyperlinks,
      :block_links,
      :require_confirmed_email,
      :minimum_account_age,
      :allow_hosting,
      :backend,
      :show_viewer_count
    ])
    |> validate_length(:chat_rules_md, max: 8192)
    |> validate_length(:title, max: 250)
    |> validate_number(:minimum_account_age,
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 720
    )
    |> validate_inclusion(:backend, ["ftl", "whep"])
    |> set_chat_rules_content_html()
    |> cast_attachments(attrs, [:poster, :chat_bg])
    |> maybe_put_tags(:tags, attrs)
    |> maybe_put_subcategory(:subcategory, attrs)
    |> unique_constraint([:user_id])
  end

  def emote_settings_changeset(channel, attrs \\ %{}) do
    channel
    |> cast(attrs, [:emote_prefix])
    |> validate_required(:emote_prefix)
    |> validate_format(:emote_prefix, ~r/^[a-zA-Z0-9]+$/i,
      message: "Emote prefix must be only alphanumeric characters"
    )
    |> validate_length(:emote_prefix, is: 5)
    |> validate_no_active_emotes()
    |> unique_constraint(:emote_prefix)
  end

  defp validate_no_active_emotes(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{emote_prefix: emote_prefix}} ->
        if Glimesh.Emotes.count_all_emotes_for_channel(changeset.data) > 0 do
          add_error(
            changeset,
            :emote_prefix,
            "For now, you must delete all of your emotes to change your prefix."
          )
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  def addons_changest(channel, attrs \\ %{}) do
    channel
    |> cast(attrs, [
      :streamloots_url,
      :show_subscribe_button,
      :show_donate_button,
      :show_streamloots_button
    ])
    |> validate_format(:streamloots_url, ~r/https:\/\/www\.streamloots\.com\/([a-zA-Z0-9._]+)/)
  end

  alias Glimesh.ChannelCategories
  alias Glimesh.Streams.Tag

  def tags_changeset(channel, tags) do
    channel
    |> change()
    |> put_assoc(:tags, tags)
  end

  def maybe_put_tags(changeset, key, %{"tags" => _tags} = attrs) do
    # Make sure we're not accidentally unsetting tags
    changeset |> put_assoc(key, parse_tags(attrs))
  end

  def maybe_put_tags(changeset, _key, _attrs) do
    changeset
  end

  def maybe_put_subcategory(changeset, key, %{"subcategory" => subcategory_json})
      when subcategory_json == "" do
    changeset |> put_assoc(key, nil)
  end

  def maybe_put_subcategory(changeset, key, %{"subcategory" => subcategory_json})
      when is_binary(subcategory_json) do
    case Jason.decode(subcategory_json) do
      {:ok, [%{"value" => value, "category_id" => category_id}]} ->
        slug = Slug.slugify(value)

        subcategory =
          if existing =
               ChannelCategories.get_subcategory_by_category_id_and_slug(category_id, slug) do
            existing
          else
            {:ok, category} =
              ChannelCategories.create_subcategory(%{
                name: value,
                user_created: true,
                category_id: category_id
              })

            category
          end

        changeset |> put_assoc(key, subcategory)

      _ ->
        changeset
    end
  end

  def maybe_put_subcategory(changeset, _, _) do
    changeset
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
    Glimesh.Streams.HmacKey.generate_key()
  end

  def change_allow_hosting(%Glimesh.Streams.Channel{} = channel, attrs \\ %{}) do
    channel
    |> cast(attrs, [:allow_hosting])
    |> validate_required(:allow_hosting)
  end

  def update_allow_hosting(%Glimesh.Streams.Channel{} = channel, attrs \\ %{}) do
    change_allow_hosting(channel, attrs)
    |> Glimesh.Repo.update()
  end

  def edit_title_and_tags_changeset(channel, attrs \\ %{}) do
    channel
    |> cast(attrs, [
      :title,
      :category_id,
      :subcategory_id
    ])
    |> validate_length(:title, max: 250)
    |> maybe_put_tags(:tags, attrs)
    |> maybe_put_subcategory(:subcategory, attrs)
    |> unique_constraint([:user_id])
  end
end
