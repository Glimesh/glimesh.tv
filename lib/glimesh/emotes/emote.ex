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
    belongs_to :approved_by, Glimesh.Accounts.User

    field :static_file, Glimesh.Uploaders.Emote.Type
    field :animated_file, Glimesh.Uploaders.AnimatedEmote.Type

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:emote, :animated, :approved_at, :static_file, :animated_file])
    |> cast_attachments(attrs, [:static_file, :animated_file])
    |> validate_required([:emote, :animated])
    |> validate_length(:emote, min: 2, max: 10)
    |> validate_conditional_file()
    |> unique_constraint(:emote)
  end

  def validate_conditional_file(changeset) do
    if get_field(changeset, :animated) do
      changeset |> validate_required(:animated_file)
    else
      changeset |> validate_required(:static_file)
    end
  end
end
