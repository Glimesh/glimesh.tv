defmodule Glimesh.Emotes.Emote do
  @moduledoc false

  use Ecto.Schema
  use Waffle.Ecto.Schema

  import Ecto.Changeset

  schema "emotes" do
    field :emote, :string
    belongs_to :channel, Glimesh.Streams.Channel
    field :animated, :boolean

    field :approved_at, :naive_datetime
    field :rejected_at, :naive_datetime
    field :rejected_reason, :string
    belongs_to :reviewed_by, Glimesh.Accounts.User

    field :static_file, Glimesh.Uploaders.StaticEmote.Type
    field :animated_file, Glimesh.Uploaders.AnimatedEmote.Type

    timestamps()
  end

  @doc false
  def changeset(emote, attrs) do
    emote
    |> cast(attrs, [:emote, :animated, :approved_at])
    |> validate_required([:emote, :animated])
    |> validate_length(:emote, min: 2, max: 15)
    |> validate_conditional_file(attrs)
    |> unique_constraint(:emote)
  end

  @doc false
  def channel_changeset(emote, %Glimesh.Streams.Channel{} = channel, attrs) do
    # This has to be its own changeset since we need to prefix before we cast_attachments so we can rename the emote.
    emote
    |> cast(attrs, [:emote, :animated, :approved_at])
    |> validate_required([:emote, :animated])
    |> prefix_emote(channel.emote_prefix)
    |> validate_length(:emote, min: 2, max: 15)
    |> validate_format(:emote, ~r/^[a-zA-Z0-9]+$/i,
      message: "Emote must be only contain alpha-numeric characters"
    )
    |> validate_channel_max_emotes(channel)
    |> validate_channel_allow_animated()
    |> validate_conditional_file(attrs)
    |> unique_constraint(:emote)
  end

  defp validate_channel_max_emotes(emote, channel) do
    config = Application.get_env(:glimesh, Glimesh.Emotes)
    count = Glimesh.Emotes.count_all_emotes_for_channel(channel)
    max = Keyword.get(config, :max_channel_emotes, 100)

    if count >= max do
      emote |> add_error(:emote, "You can only have #{max} emotes at a time.")
    else
      emote
    end
  end

  defp validate_channel_allow_animated(emote) do
    config = Application.get_env(:glimesh, Glimesh.Emotes)
    allow_animated = Keyword.get(config, :allow_channel_animated_emotes, true)

    if get_field(emote, :animated) and allow_animated == false do
      emote |> add_error(:emote, "You cannot upload animated emotes.")
    else
      emote
    end
  end

  def review_changeset(emote, reviewer, attrs) do
    emote
    |> cast(attrs, [:approved_at, :rejected_at, :rejected_reason])
    |> put_assoc(:reviewed_by, reviewer)
  end

  defp prefix_emote(emote, prefix) when is_binary(prefix) do
    emote
    |> put_change(:emote, prefix <> get_field(emote, :emote))
  end

  defp prefix_emote(emote, _) do
    emote
    |> add_error(:emote, "Emote prefix does not exist for channel")
  end

  defp validate_conditional_file(changeset, attrs) do
    if get_field(changeset, :animated) do
      changeset
      |> cast_attachments(attrs, [:animated_file], allow_paths: true)
      |> validate_required(:animated_file)
    else
      changeset
      |> cast_attachments(attrs, [:static_file], allow_paths: true)
      |> validate_required(:static_file)
    end
  end
end
