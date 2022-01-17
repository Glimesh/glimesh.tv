defmodule Glimesh.Chat.Effects.Badges.ChannelSubscriberBadge do
  @moduledoc """
  Badge for channel subscribers
  """

  alias Phoenix.HTML.Tag
  import GlimeshWeb.Gettext

  def render do
    Tag.content_tag(:span, Tag.content_tag(:i, "", class: "fas fa-trophy"),
      class: "badge badge-secondary",
      "data-toggle": "tooltip",
      title: gettext("Channel Subscriber")
    )
  end
end
