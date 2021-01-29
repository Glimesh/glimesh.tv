defmodule Glimesh.Streams.Tag do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field :identifier, :string
    field :icon, :string
    field :name, :string
    field :slug, :string

    field :count_usage, :integer, default: 1

    belongs_to :category, Glimesh.Streams.Category

    many_to_many :channels, Glimesh.Streams.Channel, join_through: "channel_tags"

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:identifier, :name, :slug, :icon, :count_usage, :category_id])
    |> validate_required([:name])
    |> validate_length(:name, min: 2, max: 18)
    |> validate_format(:name, ~r/^[A-Za-z0-9: -]{2,18}$/)
    |> set_identifier_attribute()
    |> unique_constraint(:identifier)
    |> set_slug_attribute()
  end

  def set_identifier_attribute(changeset) do
    category_name =
      if category_id = get_field(changeset, :category_id) do
        Glimesh.ChannelCategories.get_category_by_id!(category_id).name
      else
        "Global"
      end

    name = get_field(changeset, :name)

    put_change(changeset, :identifier, "#{category_name} - #{name}")
  end

  def set_slug_attribute(changeset) do
    if name = get_field(changeset, :name) do
      put_change(changeset, :slug, Slug.slugify(name))
    else
      # When nil let fail normally
      changeset
    end
  end
end
