defmodule Glimesh.ChannelCategories do
  @moduledoc """
  Channel Categories and Tags Functionality
  """

  import Ecto.Query, warn: false

  alias Glimesh.Repo
  alias Glimesh.Streams.Category
  alias Glimesh.Streams.Channel
  alias Glimesh.Streams.Tag

  ## Categories

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category)
  end

  def list_categories_for_select do
    Repo.all(from c in Category, order_by: [asc: :name])
    |> Enum.map(&{&1.name, &1.id})
  end

  @doc """
  Gets a single category.

  ## Examples

      iex> get_category(123)
      %Category{}

      iex> get_category(456)
      nil

  """
  def get_category(slug),
    do: Repo.one(from c in Category, where: c.slug == ^slug)

  def get_category_by_id!(id), do: Repo.get_by!(Category, id: id)

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  ## Tags

  @doc """
  Returns the list of tags.

  ## Examples

      iex> list_tags()
      [%Tag{}, ...]

  """
  def list_tags do
    Repo.all(from t in Tag, order_by: [desc: :count_usage]) |> Repo.preload(:category)
  end

  def list_tags(category_id) do
    Repo.all(from t in Tag, where: t.category_id == ^category_id, order_by: [desc: :count_usage])
  end

  def list_live_tags(category_id) do
    Repo.all(
      from t in Tag,
        join: c in Channel,
        join: ct in "channel_tags",
        on: ct.tag_id == t.id and ct.channel_id == c.id,
        where: c.status == "live" and t.category_id == ^category_id,
        order_by: [desc: :count_usage]
    )
  end

  def list_tags_for_tagify(category_id) do
    Repo.all(
      from t in Tag,
        where: t.category_id == ^category_id,
        order_by: [desc: :count_usage]
    )
    |> Enum.map(fn tag ->
      %{
        value: tag.name,
        label: "#{tag.name} (#{tag.count_usage} Uses)",
        # placeholder for global tags
        class: ""
      }
    end)
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.

  ## Examples

      iex> get_tag!(123)
      %Tag{}

      iex> get_tag!(456)
      ** (Ecto.NoResultsError)

  """
  def get_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Creates a tag.

  ## Examples

      iex> create_tag(%{field: value})
      {:ok, %Tag{}}

      iex> create_tag(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_tag(attrs \\ %{}) do
    upsert_tag(%Tag{}, attrs)
  end

  @doc """
  Updates a tag.

  ## Examples

      iex> update_tag(tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> update_tag(tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_tag(%Tag{} = tag, attrs) do
    # upsert_tag(tag, attrs)
    tag
    |> Tag.changeset(attrs)
    |> Repo.update()
  end

  def upsert_tag(%Tag{} = tag, attrs \\ %{}) do
    tag
    |> Tag.changeset(attrs)
    |> Repo.insert(
      returning: [:count_usage],
      on_conflict: [inc: [count_usage: 1]],
      conflict_target: [:identifier]
    )
  end

  @doc """
  Deletes a tag.

  ## Examples

      iex> delete_tag(tag)
      {:ok, %Tag{}}

      iex> delete_tag(tag)
      {:error, %Ecto.Changeset{}}

  """
  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking tag changes.

  ## Examples

      iex> change_tag(tag)
      %Ecto.Changeset{data: %Tag{}}

  """
  def change_tag(%Tag{} = tag, attrs \\ %{}) do
    Tag.changeset(tag, attrs)
  end
end
