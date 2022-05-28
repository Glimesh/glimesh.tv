defmodule GlimeshWeb.UserLive.Components.RecentTagsTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Glimesh.ChannelCategories
  alias Glimesh.Streams.Subcategory
  alias Glimesh.Streams.Tag

  @component GlimeshWeb.UserLive.Components.RecentTags

  defp create_some_dummy_subcategories(categoryId) do
    Enum.map(0..4, fn x ->
      %Subcategory{id: x, name: Faker.Superhero.name(), category: categoryId}
    end)
  end

  defp create_some_dummy_tags(categoryId) do
    Enum.map(0..9, fn x -> %Tag{id: x, name: Faker.Food.dish(), category: categoryId} end)
  end

  describe "recent categories and tags" do
    setup [:register_and_log_in_user]

    test "shows recent subcategories" do
      gaming_cat = ChannelCategories.get_category("gaming")
      tech_cat = ChannelCategories.get_category("tech")

      gaming_subcategories = create_some_dummy_subcategories(gaming_cat)

      html =
        render_component(@component, %{
          operation: "replace",
          fieldid: "category-selector",
          recent_tags: gaming_subcategories
        })

      assert html =~ "recent-tag-category-selector-#{Enum.random(gaming_subcategories).id}"
      assert html =~ "data-tagname=\"#{Enum.random(gaming_subcategories).name}\""
      assert html =~ "data-operation=\"replace\""
      assert html =~ "data-fieldid=\"category-selector\""

      tech_subcategories = create_some_dummy_subcategories(tech_cat)

      html =
        render_component(@component, %{
          operation: "replace",
          fieldid: "category-selector",
          recent_tags: tech_subcategories
        })

      assert html =~ "recent-tag-category-selector-#{Enum.random(tech_subcategories).id}"
      assert html =~ "data-tagname=\"#{Enum.random(tech_subcategories).name}\""
      assert html =~ "data-operation=\"replace\""
      assert html =~ "data-fieldid=\"category-selector\""
    end

    test "shows recent tags" do
      gaming_cat = ChannelCategories.get_category("gaming")
      tech_cat = ChannelCategories.get_category("tech")

      gaming_tags = create_some_dummy_tags(gaming_cat)

      html =
        render_component(@component, %{
          operation: "append",
          fieldid: "tag-selector",
          recent_tags: gaming_tags
        })

      assert html =~ "recent-tag-tag-selector-#{Enum.random(gaming_tags).id}"
      assert html =~ "data-tagname=\"#{Enum.random(gaming_tags).name}\""
      assert html =~ "data-operation=\"append\""
      assert html =~ "data-fieldid=\"tag-selector\""

      tech_tags = create_some_dummy_tags(tech_cat)

      html =
        render_component(@component, %{
          operation: "append",
          fieldid: "tag-selector",
          recent_tags: tech_tags
        })

      assert html =~ "recent-tag-tag-selector-#{Enum.random(tech_tags).id}"
      assert html =~ "data-tagname=\"#{Enum.random(tech_tags).name}\""
      assert html =~ "data-operation=\"append\""
      assert html =~ "data-fieldid=\"tag-selector\""
    end
  end
end
