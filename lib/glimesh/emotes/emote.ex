defmodule Glimesh.Emotes.Emote do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "emotes" do
    field :emote, :string
    belongs_to :channel, Glimesh.Streams.Channel
    field :animated, :boolean

    field :approved_at, :naive_datetime
    belongs_to :approved_by, Glimesh.Accounts.User

    field :png_file, :string
    field :svg_file, :string
    field :gif_file, :string

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:emote, :animated, :approved_at, :png_file, :svg_file, :gif_file])
    |> validate_required([:emote, :animated])
    |> validate_length(:emote, min: 2, max: 10)
    |> validate_conditional_file()
    |> unique_constraint(:emote)
  end

  def validate_conditional_file(changeset) do
    IO.inspect(get_field(changeset, :animated))
    # This may not be a boolean
    if get_field(changeset, :animated) do
      changeset |> validate_required(:gif_file)
    else
      changeset |> validate_required([:png_file, :svg_file])
    end
  end
end
