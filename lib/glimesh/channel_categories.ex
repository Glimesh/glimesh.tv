defmodule Glimesh.ChannelCategories do
  @moduledoc """
  Channel Categories and Tags Functionality
  """

  import Ecto.Query, warn: false

  alias Glimesh.Repo
  alias Glimesh.Streams.Category
  alias Glimesh.Streams.Subcategory
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
  def get_category(nil),
    do: nil

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

  def list_tags_for_channel(%Channel{} = channel) do
    Repo.all(
      from t in Tag,
        join: c in Channel,
        join: ct in "channel_tags",
        on: ct.tag_id == t.id and ct.channel_id == c.id,
        where: c.id == ^channel.id
    )
  end

  def list_live_tags(category_id) do
    Repo.all(
      from t in Tag,
        join: c in Channel,
        join: ct in "channel_tags",
        on: ct.tag_id == t.id and ct.channel_id == c.id,
        where: c.status == "live" and t.category_id == ^category_id,
        order_by: [desc: :count_usage],
        group_by: t.id
    )
  end

  def tagify_search_for_tags(%Category{} = category, search_value)
      when is_binary(search_value) do
    search_param = "%#{search_value}%"

    Repo.all(
      from t in Tag,
        where: t.category_id == ^category.id and ilike(t.name, ^search_param),
        limit: 15
    )
    |> convert_tags_for_tagify()
  end

  def list_tags_for_tagify(category_id) do
    Repo.all(
      from t in Tag,
        where: t.category_id == ^category_id,
        order_by: [desc: :count_usage]
    )
    |> convert_tags_for_tagify()
  end

  def convert_tags_for_tagify(tags, include_usage \\ true) do
    Enum.map(tags, fn tag ->
      %{
        value: tag.name,
        slug: tag.slug,
        label: "#{tag.name}" <> if(include_usage, do: " (#{tag.count_usage} Uses)", else: ""),
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

  @doc """
  Upserts a tag. Note: Does not actually update anything.

  ## Examples

      iex> upsert_tag(tag, %{field: new_value})
      {:ok, %Tag{}}

      iex> upsert_tag(tag, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def upsert_tag(%Tag{} = tag, attrs \\ %{}) do
    timestamp =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.truncate(:second)

    tag
    |> Tag.changeset(attrs)
    |> Repo.insert(
      returning: true,
      on_conflict: [set: [updated_at: timestamp]],
      conflict_target: :identifier
    )
  end

  def increment_tags_usage(tags) do
    Enum.map(tags, fn tag ->
      update_tag(tag, %{
        count_usage: tag.count_usage + 1
      })
    end)
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

  # Subcategories
  import GlimeshWeb.Gettext

  def tagify_search_for_subcategories(%Category{} = category, search_value)
      when is_binary(search_value) do
    search_param = "%#{search_value}%"

    Repo.all(
      from c in Subcategory,
        where: c.category_id == ^category.id and ilike(c.name, ^search_param),
        limit: 10
    )
    |> convert_subcategories_for_tagify()
  end

  def get_subcategory_label(%Category{slug: slug}) do
    case slug do
      "gaming" -> gettext("Game")
      "art" -> gettext("Style")
      "education" -> gettext("Topic")
      "irl" -> gettext("Topic")
      "music" -> gettext("Genre")
      "tech" -> gettext("Topic")
    end
  end

  def get_subcategory_select_label_description(%Category{slug: slug}) do
    case slug do
      "gaming" -> gettext("What game are you playing?")
      "art" -> gettext("What type of art are you doing?")
      "education" -> gettext("What topic are you teaching?")
      "irl" -> gettext("What topic are you discussing?")
      "music" -> gettext("What genre of music?")
      "tech" -> gettext("What topic are you discussing?")
    end
  end

  def get_subcategory_search_label_description(%Category{slug: slug}) do
    case slug do
      "gaming" -> gettext("Search by Game")
      "art" -> gettext("Search by Style")
      "education" -> gettext("Search by Topic")
      "irl" -> gettext("Search by Topic")
      "music" -> gettext("Search by Genre")
      "tech" -> gettext("Search by Topic")
    end
  end

  def get_subcategory_by_category_id_and_slug(category_id, slug) do
    Repo.one(from c in Subcategory, where: c.category_id == ^category_id and c.slug == ^slug)
  end

  def list_subcategories(category_id) do
    Repo.all(
      from c in Subcategory,
        where: c.category_id == ^category_id
    )
  end

  @spec list_subcategories_for_tagify(integer) :: binary
  def list_subcategories_for_tagify(category_id) do
    list_subcategories(category_id)
    |> convert_subcategories_for_tagify()
  end

  def convert_subcategories_for_tagify(subcategories) do
    Enum.map(subcategories, fn category ->
      %{
        value: category.name,
        slug: category.slug,
        label: category.name,
        # placeholder for global tags
        class: ""
      }
    end)
  end

  @doc """
  Creates a subcategory.

  ## Examples

      iex> create_subcategory(%{field: value})
      {:ok, %Category{}}

      iex> create_subcategory(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subcategory(attrs \\ %{}) do
    %Subcategory{}
    |> Subcategory.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a subcategory.

  ## Examples

      iex> update_subcategory(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_subcategory(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subcategory(%Subcategory{} = category, attrs) do
    category
    |> Subcategory.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Creates or updates a subcategory based on source+source_id existance
  """
  @spec upsert_subcategory_from_source(binary(), binary(), map) ::
          {:ok, %Category{}} | {:error, any()}
  def upsert_subcategory_from_source(source, source_id, attrs) do
    if subcategory = subcategory_source_exists?(source, source_id) do
      update_subcategory(subcategory, attrs)
    else
      insert_map =
        Map.merge(attrs, %{
          source: source,
          source_id: source_id
        })

      create_subcategory(insert_map)
    end
  end

  defp subcategory_source_exists?(source, source_id) do
    Repo.one(from s in Subcategory, where: s.source == ^source and s.source_id == ^source_id)
  end
end
