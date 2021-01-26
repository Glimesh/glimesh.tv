defmodule Glimesh.ChannelCategoriesTest do
  use Glimesh.DataCase
  use Bamboo.Test

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

    def tag_fixture(attrs \\ %{}) do
      {:ok, tag} =
        attrs
        |> Enum.into(@valid_attrs)
        |> ChannelCategories.create_tag()

      tag
    end

    test "list_tags/0 returns all tags" do
      tag = tag_fixture()
      assert Enum.member?(Enum.map(ChannelCategories.list_tags(), fn x -> x.name end), tag.name)
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

    test "upsert_tag/2 creates a tag or increments if exists" do
      assert {:ok, %Tag{} = tag} = ChannelCategories.upsert_tag(%Tag{name: "Hello World"})
      assert tag.name == "Hello World"
      assert tag.slug == "hello-world"
      assert tag.count_usage == 1

      # Test recreating it
      assert {:ok, %Tag{} = new_tag} = ChannelCategories.upsert_tag(%Tag{name: "Hello World"})
      assert tag.id == new_tag.id
      assert new_tag.name == "Hello World"
      assert new_tag.slug == "hello-world"
      assert new_tag.count_usage == 2

      assert {:ok, %Tag{} = one_more} = ChannelCategories.upsert_tag(%Tag{name: "Hello World"})
      assert one_more.count_usage == 3
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
  end
end
