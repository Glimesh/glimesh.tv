defmodule Glimesh.Streams.Subcategory do
  @moduledoc false

  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  # @derive {Jason.Encoder, only: [:id, :name, :slug, :category_id]}
  schema "subcategories" do
    belongs_to :category, Glimesh.Streams.Category

    field :name, :string
    field :slug, :string

    field :user_created, :boolean
    field :source, :string, default: nil
    field :source_id, :string

    field :background_image, :string

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [
      :category_id,
      :name,
      :slug,
      :user_created,
      :source,
      :source_id,
      :background_image
    ])
    |> validate_required([:name])
    |> validate_length(:name, min: 2)
    |> set_slug_attribute()
    |> unique_constraint([:category_id, :slug])
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
