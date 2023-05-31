defmodule Glimesh.Streams.Category do
  @moduledoc false

  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:name, :slug]}
  schema "categories" do
    field :name, :string
    field :slug, :string

    has_many :tags, Glimesh.Streams.Tag
    has_many :subcategories, Glimesh.Streams.Subcategory

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [
      :name,
      :slug
    ])
    |> validate_required([:name])
    |> validate_length(:name, min: 2)
    |> set_slug_attribute()
    |> unique_constraint([:slug])
  end

  def set_slug_attribute(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{name: name}} ->
        put_change(changeset, :slug, Slug.slugify(name))

      _ ->
        changeset
    end
  end
end
