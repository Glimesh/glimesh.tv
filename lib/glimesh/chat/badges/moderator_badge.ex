defmodule Glimesh.Chat.Effects.Badges.ModeratorBadge do
  @moduledoc """
  Badge for streamers
  """

  alias Phoenix.HTML.Tag

  def render do
    Tag.content_tag(:span, "Mod", class: "badge badge-primary")
  end
end
