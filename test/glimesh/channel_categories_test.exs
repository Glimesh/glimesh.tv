defmodule Glimesh.ChannelCategoriesTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures
  alias Glimesh.ChannelCategories

  describe "categories" do
    alias Glimesh.Streams.Category

    @valid_attrs %{
      name: "some name"
    }
    @update_attrs %{
      name: "some updated name"
    }
    @invalid_attrs %{name: nil}

    def category_fixture(attrs \\ %{}) do
      {:ok, category} =
        attrs
        |> Enum.into(@valid_attrs)
        |> ChannelCategories.create_category()

      category
    end

    test "list_categories/0 returns all categories" do
      category = category_fixture()

      assert Enum.member?(
               Enum.map(ChannelCategories.list_categories(), fn x -> x.name end),
               category.name
             )
    end

    test "get_category_by_id!/1 returns the category with given id" do
      category = category_fixture()
      assert ChannelCategories.get_category_by_id!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      assert {:ok, %Category{} = category} = ChannelCategories.create_category(@valid_attrs)
      assert category.name == "some name"
      assert category.slug == "some-name"
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ChannelCategories.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()

      assert {:ok, %Category{} = category} =
               ChannelCategories.update_category(category, @update_attrs)

      assert category.name == "some updated name"
      assert category.slug == "some-updated-name"
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()

      assert {:error, %Ecto.Changeset{}} =
               ChannelCategories.update_category(category, @invalid_attrs)

      assert category == ChannelCategories.get_category_by_id!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = ChannelCategories.delete_category(category)

      assert_raise Ecto.NoResultsError, fn ->
        ChannelCategories.get_category_by_id!(category.id)
      end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = ChannelCategories.change_category(category)
    end
  end

  describe "tags" do
    alias Glimesh.Streams.Tag

    @valid_attrs %{
      count_usage: 42,
      name: "some name"
    }
    @update_attrs %{
      count_usage: 43,
      name: "some updated name"
    }
    @invalid_attrs %{category_id: nil, count_usage: nil, icon: nil, name: nil, slug: nil}

    test "list_tags/0 returns all tags" do
      tag = tag_fixture()
      assert Enum.member?(Enum.map(ChannelCategories.list_tags(), fn x -> x.name end), tag.name)
    end

    test "list_tags/1 returns all tags in a category" do
      %Glimesh.Streams.Category{id: cat_id} = ChannelCategories.get_category("gaming")
      tag = tag_fixture(%{category_id: cat_id})

      assert Enum.member?(
               Enum.map(ChannelCategories.list_tags(cat_id), fn x -> x.name end),
               tag.name
             )
    end

    test "list_live_tags/1 returns only live tags" do
      streamer = streamer_fixture()
      category_id = streamer.channel.category_id

      offline_tag = tag_fixture(%{name: "Offline Tag", category_id: category_id})
      live_tag = tag_fixture(%{name: "Online Tag", category_id: category_id})

      {:ok, channel} =
        streamer.channel
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:tags, [live_tag])
        |> Glimesh.Repo.update()

      {:ok, _} = Glimesh.Streams.start_stream(channel)

      assert Enum.member?(
               Enum.map(ChannelCategories.list_live_tags(category_id), fn x -> x.name end),
               live_tag.name
             )

      refute Enum.member?(
               Enum.map(ChannelCategories.list_live_tags(category_id), fn x -> x.name end),
               offline_tag.name
             )
    end

    test "get_tag!/1 returns the tag with given id" do
      tag = tag_fixture()
      assert ChannelCategories.get_tag!(tag.id) == tag
    end

    test "create_tag/1 with valid data creates a tag" do
      assert {:ok, %Tag{} = tag} = ChannelCategories.create_tag(@valid_attrs)
      assert tag.name == "some name"
      assert tag.slug == "some-name"
    end

    test "create_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ChannelCategories.create_tag(@invalid_attrs)
    end

    test "update_tag/2 with valid data updates the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{} = tag} = ChannelCategories.update_tag(tag, @update_attrs)
      assert tag.name == "some updated name"
    end

    test "update_tag/2 with invalid data returns error changeset" do
      tag = tag_fixture()
      assert {:error, %Ecto.Changeset{}} = ChannelCategories.update_tag(tag, @invalid_attrs)
      assert tag == ChannelCategories.get_tag!(tag.id)
    end

    test "upsert_tag/2 dedupes automatically" do
      assert {:ok, %Tag{} = tag} = ChannelCategories.upsert_tag(%Tag{name: "Hello World"})
      assert tag.name == "Hello World"
      assert tag.slug == "hello-world"

      assert {:ok, %Tag{} = similar_tag} = ChannelCategories.upsert_tag(%Tag{name: "hello world"})
      assert tag.id == similar_tag.id
      # Keeps original name set above
      assert similar_tag.name == "Hello World"
    end

    test "delete_tag/1 deletes the tag" do
      tag = tag_fixture()
      assert {:ok, %Tag{}} = ChannelCategories.delete_tag(tag)
      assert_raise Ecto.NoResultsError, fn -> ChannelCategories.get_tag!(tag.id) end
    end

    test "change_tag/1 returns a tag changeset" do
      tag = tag_fixture()
      assert %Ecto.Changeset{} = ChannelCategories.change_tag(tag)
    end

    test "going live with a tag increments usage" do
      streamer = streamer_fixture()
      category_id = streamer.channel.category_id

      tag = tag_fixture(%{name: "Online Tag", category_id: category_id})

      {:ok, channel} =
        streamer.channel
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:tags, [tag])
        |> Glimesh.Repo.update()

      {:ok, _} = Glimesh.Streams.start_stream(channel)

      new_tag = ChannelCategories.get_tag!(tag.id)

      assert new_tag.count_usage == 1
    end
  end
end
