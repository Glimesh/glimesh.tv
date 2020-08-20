defmodule Glimesh.StreamLayout.FollowersHomepage do
  @moduledoc """
  FollowersHomepage is responsible for building an a list of streams that are live.
  """
  import GlimeshWeb.Gettext

  alias Glimesh.StreamLayout.PageSection
  alias Glimesh.Streams

  def generate_following_page(user) do
    new_page()
    |> set_title()
    |> set_section(user)
    |> set_layout()
  end

  def new_page do
    %{}
  end

  def set_title(page) do
    Map.put(page, :title, dgettext("navbar", "Following"))
  end

  def set_section(page, user) do
    streams = Streams.list_followed_streams(user)

    sections = [
      %PageSection{
        # Title of the section
        title: "Your Followed Streams",
        # How the category should show up, eg: half, full
        layout: "full",
        bs_parent_class: "col-md-12",
        bs_child_class: "col-md-3",

        # Streams that should be shown in order
        streams: streams
      }
    ]

    Map.put(page, :sections, sections)
  end

  def set_layout(page) do
    layout =
      case page.sections do
        [] -> "none"
        _ -> "category-top"
      end

    Map.put(page, :layout, layout)
  end
end
