defmodule Glimesh.StreamLayout.CategoryHomepage do
  @moduledoc """
  CategoryHomepage is responsible for building an engaging, filled category page, or telling the frontend when that's not possible.

      %{
        # Controls where the categories are positioned on the page, eg: category-bottom, category-top, none
        title: "Music",
        layout: "category-top",
        sections: [
          %PageSection{
            # Title of the section
            title: "Live Band",
            # How the category should show up, eg: half, full
            layout: "full",
            # Streams that should be shown in order
            streams: Glimesh.Streams.list_streams()
          }
        ]
      }
  """

  # alias Glimesh.StreamLayout.PageSection
  # alias Glimesh.Streams

  # def generate_category_page(category) do
  #   subcategories = Streams.list_categories_by_parent(category)

  #   new_page()
  #   |> set_title(category)
  #   |> set_sections(category, subcategories)
  #   |> sort_sections()
  #   |> set_layout()
  # end

  # def new_page do
  #   %{}
  # end

  # def set_title(page, category) do
  #   Map.put(page, :title, category.name)
  # end

  # @spec set_sections(map, any, [atom | %{id: any, name: any}]) :: %{sections: any}
  # def set_sections(page, _category, subcategories) do
  #   Map.put(page, :sections, build_subcategories(subcategories, []))
  # end

  # def set_layout(page) do
  #   layout =
  #     case page.sections do
  #       [] -> "none"
  #       _ -> "category-top"
  #     end

  #   Map.put(page, :layout, layout)
  # end

  # def sort_sections(page) do
  #   page
  # end

  # def build_subcategories([category | tail], sections) do
  #   channels = Glimesh.Streams.list_in_category(category)
  #   layout = if length(channels) < 5, do: "half", else: "full"
  #   bs_parent_class = if length(channels) < 5, do: "col-md-6", else: "col-md-12"
  #   bs_child_class = if length(channels) < 5, do: "col-md-6", else: "col-md-3"

  #   section = %PageSection{
  #     # Title of the section
  #     title: category.name,
  #     # How the category should show up, eg: half, full
  #     layout: layout,
  #     bs_parent_class: bs_parent_class,
  #     bs_child_class: bs_child_class,

  #     # Streams that should be shown in order
  #     channels: channels
  #   }

  #   if length(channels) > 0 do
  #     build_subcategories(tail, [section | sections])
  #   else
  #     build_subcategories(tail, sections)
  #   end
  # end

  # def build_subcategories([], sections) do
  #   sections
  # end
end
