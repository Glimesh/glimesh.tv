defmodule Glimesh.ChannelCategoriesTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures
  import Glimesh.Factory
  import Glimesh.Streams.Channel

  alias Glimesh.AccountsFixtures
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

  describe "subcategories" do
    alias Glimesh.Streams.Category
    alias Glimesh.Streams.Subcategory

    @update_attrs %{
      name: "some updated name"
    }
    @invalid_attrs %{name: nil}

    setup do
      subcategory = subcategory_fixture() |> Glimesh.Repo.preload(:category)

      %{
        category: subcategory.category,
        subcategory: subcategory
      }
    end

    test "list_subcategories/1 returns all subcategories for a category", %{
      subcategory: subcategory,
      category: category
    } do
      assert Enum.member?(
               Enum.map(ChannelCategories.list_subcategories(category), fn x -> x.name end),
               subcategory.name
             )
    end

    test "list_subcategories_for_tagify/1 returns the right stuff", %{
      subcategory: subcategory,
      category: category
    } do
      assert ChannelCategories.list_subcategories_for_tagify(category) == [
               %{
                 value: subcategory.name,
                 slug: subcategory.slug,
                 label: subcategory.name,
                 class: ""
               }
             ]
    end

    test "update_category/2 with valid data updates the category", %{subcategory: subcategory} do
      assert {:ok, %Subcategory{} = subcategory} =
               ChannelCategories.update_subcategory(subcategory, @update_attrs)

      assert subcategory.name == "some updated name"
      assert subcategory.slug == "some-updated-name"
    end

    test "update_subcategory/2 with invalid data returns error changeset", %{
      subcategory: subcategory,
      category: category
    } do
      assert {:error, %Ecto.Changeset{}} =
               ChannelCategories.update_subcategory(subcategory, @invalid_attrs)

      assert subcategory ==
               ChannelCategories.get_subcategory_by_category_id_and_slug(
                 category.id,
                 subcategory.slug
               )
    end

    test "upsert_subcategory_from_source/3 upserts" do
      assert {:ok, %Subcategory{} = subcategory} =
               ChannelCategories.upsert_subcategory_from_source("fake-source", "123", %{
                 name: "Hello world"
               })

      assert {:ok, %Subcategory{} = new_subcategory} =
               ChannelCategories.upsert_subcategory_from_source("fake-source", "123", %{
                 name: "Derp"
               })

      assert subcategory.id == new_subcategory.id
    end

    test "get_subcategory_label/1 returns correct values" do
      assert ChannelCategories.get_subcategory_label(%Category{slug: "gaming"}) == "Game"
      assert ChannelCategories.get_subcategory_label(%Category{slug: "art"}) == "Style"
      assert ChannelCategories.get_subcategory_label(%Category{slug: "education"}) == "Topic"
      assert ChannelCategories.get_subcategory_label(%Category{slug: "irl"}) == "Topic"
      assert ChannelCategories.get_subcategory_label(%Category{slug: "music"}) == "Genre"
      assert ChannelCategories.get_subcategory_label(%Category{slug: "tech"}) == "Topic"
    end

    test "get_subcategory_select_label_description/1 returns correct values" do
      assert ChannelCategories.get_subcategory_select_label_description(%Category{slug: "gaming"}) ==
               "What game are you playing?"

      assert ChannelCategories.get_subcategory_select_label_description(%Category{slug: "art"}) ==
               "What type of art are you doing?"

      assert ChannelCategories.get_subcategory_select_label_description(%Category{
               slug: "education"
             }) == "What topic are you teaching?"

      assert ChannelCategories.get_subcategory_select_label_description(%Category{slug: "irl"}) ==
               "What topic are you discussing?"

      assert ChannelCategories.get_subcategory_select_label_description(%Category{slug: "music"}) ==
               "What genre of music?"

      assert ChannelCategories.get_subcategory_select_label_description(%Category{slug: "tech"}) ==
               "What topic are you discussing?"
    end

    test "get_subcategory_search_label_description/1 returns correct values" do
      assert ChannelCategories.get_subcategory_search_label_description(%Category{slug: "gaming"}) ==
               "Search by Game"

      assert ChannelCategories.get_subcategory_search_label_description(%Category{slug: "art"}) ==
               "Search by Style"

      assert ChannelCategories.get_subcategory_search_label_description(%Category{
               slug: "education"
             }) == "Search by Topic"

      assert ChannelCategories.get_subcategory_search_label_description(%Category{slug: "irl"}) ==
               "Search by Topic"

      assert ChannelCategories.get_subcategory_search_label_description(%Category{slug: "music"}) ==
               "Search by Genre"

      assert ChannelCategories.get_subcategory_search_label_description(%Category{slug: "tech"}) ==
               "Search by Topic"
    end
  end

  defp create_old_streams_with_tags(_) do
    gaming_cat = ChannelCategories.get_category("gaming")
    tech_cat = ChannelCategories.get_category("tech")

    old_game_subcats =
      insert_list(5, :subcategory, %{name: Faker.Superhero.name(), category: gaming_cat})

    old_tech_subcats =
      insert_list(5, :subcategory, %{name: Faker.Beer.malt(), category: tech_cat})

    old_game_tags = insert_list(10, :tag, %{name: Faker.Food.dish(), category: gaming_cat})
    old_game_tags_ids = Enum.map(old_game_tags, fn k -> k.id end)
    old_tech_tags = insert_list(10, :tag, %{name: Faker.Cat.breed(), category: tech_cat})
    old_tech_tags_ids = Enum.map(old_tech_tags, fn k -> k.id end)

    gaming_streamer =
      AccountsFixtures.streamer_fixture(%{}, %{
        category_id: gaming_cat.id,
        subcategory_id: Enum.at(old_game_subcats, 4).id,
        tags: Enum.slice(old_game_tags, 7, 2),
        language: "en"
      })

    tech_streamer =
      AccountsFixtures.streamer_fixture(%{}, %{
        category_id: tech_cat.id,
        subcategory_id: Enum.at(old_tech_subcats, 4).id,
        tags: Enum.slice(old_tech_tags, 7, 2),
        language: "en"
      })

    old_game_stream_one =
      insert(:stream, %{
        channel_id: gaming_streamer.channel.id,
        category_id: gaming_cat.id,
        subcategory_id: Enum.at(old_game_subcats, 2).id,
        category_tags: Enum.slice(old_game_tags_ids, 0, 3),
        started_at: NaiveDateTime.utc_now(),
        ended_at: NaiveDateTime.utc_now()
      })

    old_game_stream_two =
      insert(:stream, %{
        channel_id: gaming_streamer.channel.id,
        category_id: gaming_cat.id,
        subcategory_id: Enum.at(old_game_subcats, 3).id,
        category_tags: Enum.slice(old_game_tags_ids, 3, 3),
        started_at: NaiveDateTime.utc_now(),
        ended_at: NaiveDateTime.utc_now()
      })

    old_tech_stream_one =
      insert(:stream, %{
        channel_id: tech_streamer.channel.id,
        category_id: tech_cat.id,
        subcategory_id: Enum.at(old_tech_subcats, 2).id,
        category_tags: Enum.slice(old_tech_tags_ids, 0, 3),
        started_at: NaiveDateTime.utc_now(),
        ended_at: NaiveDateTime.utc_now()
      })

    old_tech_stream_two =
      insert(:stream, %{
        channel_id: tech_streamer.channel.id,
        category_id: tech_cat.id,
        subcategory_id: Enum.at(old_tech_subcats, 3).id,
        category_tags: Enum.slice(old_tech_tags_ids, 3, 3),
        started_at: NaiveDateTime.utc_now(),
        ended_at: NaiveDateTime.utc_now()
      })

    %{
      gaming_streamer: gaming_streamer,
      tech_streamer: tech_streamer,
      old_game_stream_one: old_game_stream_one,
      old_game_stream_two: old_game_stream_two,
      old_tech_stream_one: old_tech_stream_one,
      old_tech_stream_two: old_tech_stream_two
    }
  end

  describe "Recent Subcategories and Tags" do
    alias Glimesh.ChannelLookups
    alias Glimesh.Streams.Tag

    setup [:create_old_streams_with_tags]

    test "shows most recent subcategories", %{
      gaming_streamer: gaming_streamer,
      tech_streamer: tech_streamer,
      old_game_stream_one: game_stream_one,
      old_game_stream_two: game_stream_two,
      old_tech_stream_one: tech_stream_one,
      old_tech_stream_two: tech_stream_two
    } do
      recent_game_subcats =
        ChannelCategories.get_channel_recent_subcategories_for_category(gaming_streamer.channel)

      recent_tech_subcats =
        ChannelCategories.get_channel_recent_subcategories_for_category(tech_streamer.channel)

      assert Enum.any?(recent_game_subcats, fn x -> game_stream_one.subcategory_id == x.id end)
      refute Enum.any?(recent_tech_subcats, fn x -> game_stream_one.subcategory_id == x.id end)
      assert Enum.any?(recent_game_subcats, fn x -> game_stream_two.subcategory_id == x.id end)
      refute Enum.any?(recent_tech_subcats, fn x -> game_stream_two.subcategory_id == x.id end)

      assert Enum.any?(recent_tech_subcats, fn x -> tech_stream_one.subcategory_id == x.id end)
      refute Enum.any?(recent_game_subcats, fn x -> tech_stream_one.subcategory_id == x.id end)
      assert Enum.any?(recent_tech_subcats, fn x -> tech_stream_two.subcategory_id == x.id end)
      refute Enum.any?(recent_game_subcats, fn x -> tech_stream_two.subcategory_id == x.id end)
    end

    test "shows most recent tags", %{
      gaming_streamer: gaming_streamer,
      tech_streamer: tech_streamer,
      old_game_stream_one: game_stream_one,
      old_game_stream_two: game_stream_two,
      old_tech_stream_one: tech_stream_one,
      old_tech_stream_two: tech_stream_two
    } do
      recent_game_tags =
        ChannelCategories.get_channel_recent_tags_for_category(gaming_streamer.channel)

      recent_tech_tags =
        ChannelCategories.get_channel_recent_tags_for_category(tech_streamer.channel)

      assert Enum.all?(game_stream_one.category_tags, fn x ->
               Enum.find_value(recent_game_tags, false, fn y -> y.id == x end)
             end)

      refute Enum.all?(game_stream_one.category_tags, fn x ->
               Enum.find_value(recent_tech_tags, false, fn y -> y.id == x end)
             end)

      assert Enum.all?(game_stream_two.category_tags, fn x ->
               Enum.find_value(recent_game_tags, false, fn y -> y.id == x end)
             end)

      refute Enum.all?(game_stream_two.category_tags, fn x ->
               Enum.find_value(recent_tech_tags, false, fn y -> y.id == x end)
             end)

      assert Enum.all?(tech_stream_one.category_tags, fn x ->
               Enum.find_value(recent_tech_tags, false, fn y -> y.id == x end)
             end)

      refute Enum.all?(tech_stream_one.category_tags, fn x ->
               Enum.find_value(recent_game_tags, false, fn y -> y.id == x end)
             end)

      assert Enum.all?(tech_stream_two.category_tags, fn x ->
               Enum.find_value(recent_tech_tags, false, fn y -> y.id == x end)
             end)

      refute Enum.all?(tech_stream_two.category_tags, fn x ->
               Enum.find_value(recent_game_tags, false, fn y -> y.id == x end)
             end)
    end

    test "does not show duplicate recent subcategories or tags", %{
      gaming_streamer: gaming_streamer,
      tech_streamer: tech_streamer,
      old_game_stream_one: game_stream_one,
      old_tech_stream_one: tech_stream_one
    } do
      gaming_cat = ChannelCategories.get_category("gaming")
      tech_cat = ChannelCategories.get_category("tech")

      old_game_stream_duplicate =
        insert(:stream, %{
          channel_id: gaming_streamer.channel.id,
          category_id: gaming_cat.id,
          subcategory_id: game_stream_one.subcategory_id,
          category_tags: game_stream_one.category_tags,
          started_at: NaiveDateTime.utc_now(),
          ended_at: NaiveDateTime.utc_now()
        })

      old_tech_stream_duplicate =
        insert(:stream, %{
          channel_id: tech_streamer.channel.id,
          category_id: tech_cat.id,
          subcategory_id: tech_stream_one.subcategory_id,
          category_tags: tech_stream_one.category_tags,
          started_at: NaiveDateTime.utc_now(),
          ended_at: NaiveDateTime.utc_now()
        })

      recent_game_subcats =
        ChannelCategories.get_channel_recent_subcategories_for_category(gaming_streamer.channel)

      recent_tech_subcats =
        ChannelCategories.get_channel_recent_subcategories_for_category(tech_streamer.channel)

      assert Enum.count(recent_game_subcats, fn x ->
               old_game_stream_duplicate.subcategory_id == x.id
             end) == 1

      assert Enum.count(recent_tech_subcats, fn x ->
               old_tech_stream_duplicate.subcategory_id == x.id
             end) == 1

      recent_game_tags =
        ChannelCategories.get_channel_recent_tags_for_category(gaming_streamer.channel)

      recent_tech_tags =
        ChannelCategories.get_channel_recent_tags_for_category(tech_streamer.channel)

      assert Enum.count(recent_game_tags, fn x ->
               Enum.find_value(old_game_stream_duplicate.category_tags, fn y -> y == x.id end)
             end) == Enum.count(old_game_stream_duplicate.category_tags)

      assert Enum.count(recent_tech_tags, fn x ->
               Enum.find_value(old_tech_stream_duplicate.category_tags, fn y -> y == x.id end)
             end) == Enum.count(old_tech_stream_duplicate.category_tags)
    end

    test "recent subcategories and tags does not include the channel-level (last used) subcategory or tags",
         %{
           gaming_streamer: gaming_streamer,
           tech_streamer: tech_streamer,
           old_game_stream_one: game_stream_one,
           old_tech_stream_one: tech_stream_one
         } do
      game_tags =
        Tag
        |> where([t], t.id in ^game_stream_one.category_tags)
        |> Repo.all()

      tech_tags =
        Tag
        |> where([t], t.id in ^tech_stream_one.category_tags)
        |> Repo.all()

      gaming_streamer.channel
      |> changeset(%{subcategory_id: game_stream_one.subcategory_id})
      |> put_assoc(:tags, game_tags)
      |> Repo.update()

      tech_streamer.channel
      |> changeset(%{subcategory_id: tech_stream_one.subcategory_id})
      |> put_assoc(:tags, tech_tags)
      |> Repo.update()

      gaming_streamer_channel = ChannelLookups.get_channel(gaming_streamer.channel.id)
      tech_streamer_channel = ChannelLookups.get_channel(tech_streamer.channel.id)

      recent_game_subcats =
        ChannelCategories.get_channel_recent_subcategories_for_category(gaming_streamer_channel)

      recent_tech_subcats =
        ChannelCategories.get_channel_recent_subcategories_for_category(tech_streamer_channel)

      recent_game_tags =
        ChannelCategories.get_channel_recent_tags_for_category(gaming_streamer_channel)

      recent_tech_tags =
        ChannelCategories.get_channel_recent_tags_for_category(tech_streamer_channel)

      refute Enum.find_value(recent_game_subcats, fn x ->
               gaming_streamer_channel.subcategory_id == x.id
             end)

      refute Enum.find_value(recent_tech_subcats, fn x ->
               tech_streamer_channel.subcategory_id == x.id
             end)

      refute Enum.find_value(recent_game_tags, fn x ->
               Enum.find_value(gaming_streamer_channel.tags, fn y -> y == x.id end)
             end)

      refute Enum.find_value(recent_tech_tags, fn x ->
               Enum.find_value(tech_streamer_channel.tags, fn y -> y == x.id end)
             end)
    end

    test "no recent subcategories if no previous streams in category", %{
      gaming_streamer: gaming_streamer,
      tech_streamer: tech_streamer,
      old_game_stream_one: game_stream_one,
      old_game_stream_two: game_stream_two,
      old_tech_stream_one: tech_stream_one,
      old_tech_stream_two: tech_stream_two
    } do
      art_cat = ChannelCategories.get_category("art")

      recent_game_subcats =
        ChannelCategories.get_channel_recent_subcategories_for_category(
          gaming_streamer.channel,
          "#{art_cat.id}"
        )

      recent_tech_subcats =
        ChannelCategories.get_channel_recent_subcategories_for_category(
          tech_streamer.channel,
          "#{art_cat.id}"
        )

      refute Enum.any?(recent_game_subcats, fn x -> game_stream_one.subcategory_id == x.id end)
      refute Enum.any?(recent_game_subcats, fn x -> game_stream_two.subcategory_id == x.id end)
      refute Enum.any?(recent_tech_subcats, fn x -> tech_stream_one.subcategory_id == x.id end)
      refute Enum.any?(recent_tech_subcats, fn x -> tech_stream_two.subcategory_id == x.id end)
    end

    test "no recent tags if no previous streams in category", %{
      gaming_streamer: gaming_streamer,
      tech_streamer: tech_streamer,
      old_game_stream_one: game_stream_one,
      old_game_stream_two: game_stream_two,
      old_tech_stream_one: tech_stream_one,
      old_tech_stream_two: tech_stream_two
    } do
      art_cat = ChannelCategories.get_category("art")

      recent_game_tags =
        ChannelCategories.get_channel_recent_tags_for_category(
          gaming_streamer.channel,
          "#{art_cat.id}"
        )

      recent_tech_tags =
        ChannelCategories.get_channel_recent_tags_for_category(
          tech_streamer.channel,
          "#{art_cat.id}"
        )

      refute Enum.all?(game_stream_one.category_tags, fn x ->
               Enum.find_value(recent_game_tags, false, fn y -> y.id == x end)
             end)

      refute Enum.all?(game_stream_two.category_tags, fn x ->
               Enum.find_value(recent_game_tags, false, fn y -> y.id == x end)
             end)

      refute Enum.all?(tech_stream_one.category_tags, fn x ->
               Enum.find_value(recent_tech_tags, false, fn y -> y.id == x end)
             end)

      refute Enum.all?(tech_stream_two.category_tags, fn x ->
               Enum.find_value(recent_tech_tags, false, fn y -> y.id == x end)
             end)
    end

    test "should still show recent subcategories if no channel subcategory set", %{
      gaming_streamer: gaming_streamer,
      tech_streamer: tech_streamer,
      old_game_stream_one: game_stream_one,
      old_game_stream_two: game_stream_two,
      old_tech_stream_one: tech_stream_one,
      old_tech_stream_two: tech_stream_two
    } do
      gaming_streamer.channel
      |> changeset(%{subcategory_id: nil})
      |> Repo.update()

      tech_streamer.channel
      |> changeset(%{subcategory_id: nil})
      |> Repo.update()

      gaming_streamer_channel = ChannelLookups.get_channel(gaming_streamer.channel.id)
      tech_streamer_channel = ChannelLookups.get_channel(tech_streamer.channel.id)

      recent_game_subcats =
        ChannelCategories.get_channel_recent_subcategories_for_category(gaming_streamer_channel)

      recent_tech_subcats =
        ChannelCategories.get_channel_recent_subcategories_for_category(tech_streamer_channel)

      assert Enum.count(recent_game_subcats) == 2
      assert Enum.count(recent_tech_subcats) == 2
      assert Enum.any?(recent_game_subcats, fn x -> game_stream_one.subcategory_id == x.id end)
      assert Enum.any?(recent_game_subcats, fn x -> game_stream_two.subcategory_id == x.id end)
      assert Enum.any?(recent_tech_subcats, fn x -> tech_stream_one.subcategory_id == x.id end)
      assert Enum.any?(recent_tech_subcats, fn x -> tech_stream_two.subcategory_id == x.id end)
    end

    test "should still show most recent tags if no channel tags set", %{
      gaming_streamer: gaming_streamer,
      tech_streamer: tech_streamer,
      old_game_stream_one: game_stream_one,
      old_game_stream_two: game_stream_two,
      old_tech_stream_one: tech_stream_one,
      old_tech_stream_two: tech_stream_two
    } do
      gaming_streamer.channel
      |> changeset()
      |> put_assoc(:tags, nil)
      |> Repo.update()

      tech_streamer.channel
      |> changeset()
      |> put_assoc(:tags, nil)
      |> Repo.update()

      gaming_streamer_channel = ChannelLookups.get_channel(gaming_streamer.channel.id)
      tech_streamer_channel = ChannelLookups.get_channel(tech_streamer.channel.id)

      recent_game_tags =
        ChannelCategories.get_channel_recent_tags_for_category(gaming_streamer_channel)

      recent_tech_tags =
        ChannelCategories.get_channel_recent_tags_for_category(tech_streamer_channel)

      assert Enum.count(recent_game_tags) ==
               Enum.count(game_stream_one.category_tags) +
                 Enum.count(game_stream_two.category_tags)

      assert Enum.count(recent_tech_tags) ==
               Enum.count(tech_stream_one.category_tags) +
                 Enum.count(tech_stream_two.category_tags)

      assert Enum.all?(game_stream_one.category_tags, fn x ->
               Enum.find_value(recent_game_tags, false, fn y -> y.id == x end)
             end)

      assert Enum.all?(game_stream_two.category_tags, fn x ->
               Enum.find_value(recent_game_tags, false, fn y -> y.id == x end)
             end)

      assert Enum.all?(tech_stream_one.category_tags, fn x ->
               Enum.find_value(recent_tech_tags, false, fn y -> y.id == x end)
             end)

      assert Enum.all?(tech_stream_two.category_tags, fn x ->
               Enum.find_value(recent_tech_tags, false, fn y -> y.id == x end)
             end)
    end
  end
end
