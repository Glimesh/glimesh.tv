defmodule Glimesh.Streams.Category do
  @moduledoc false

  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :tag_name, :string
    field :slug, :string
    # field :parent_id, :integer
    field :avatar, Glimesh.CategoryAvatar.Type
    belongs_to :parent, Glimesh.Streams.Category

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :slug, :parent_id])
    # |> cast_attachments(attrs, [:avatar])
    |> validate_required([:name])
    |> validate_length(:name, min: 2)
    |> set_slug_attribute()
    |> set_tag_name_attribute()
  end

  def set_tag_name_attribute(changeset) do
    name = get_field(changeset, :name)

    case get_field(changeset, :parent_id) do
      nil ->
        put_change(changeset, :tag_name, name)

      parent_id ->
        parent = Glimesh.Streams.get_category_by_id!(parent_id)
        put_change(changeset, :tag_name, "#{name} > #{parent.name}")
    end
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
