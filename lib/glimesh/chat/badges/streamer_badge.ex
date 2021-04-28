defmodule Glimesh.Chat.Effects.Badges.StreamerBadge do
  @moduledoc """
  Badge for streamers
  """

  alias Phoenix.HTML.Tag

  def render do
    Tag.content_tag(:span, "Streamer", class: "badge badge-primary")
  end
end
