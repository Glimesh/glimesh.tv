defmodule Glimesh.Chat.Effects do
  @moduledoc """

  """

  import GlimeshWeb.Gettext

  alias Glimesh.Payments
  alias Phoenix.HTML.Tag
  alias GlimeshWeb.Router.Helpers, as: Routes

  def render_global_badge(_user) do
    # if user.is_admin do
    #   Tag.content_tag(:span, "Team Glimesh", class: "badge badge-danger")
    # else
    #   ""
    # end

    ""
  end

  def render_username(user) do
    tags =
      cond do
        user.is_admin ->
          [class: "text-danger", "data-toggle": "tooltip", title: gettext("Glimesh Staff")]

        Payments.is_platform_founder_subscriber?(user) ->
          [
            class: "text-warning",
            "data-toggle": "tooltip",
            title: gettext("Glimesh Founder Subscriber")
          ]

        Payments.is_platform_supporter_subscriber?(user) ->
          [
            class: "text-white",
            "data-toggle": "tooltip",
            title: gettext("Glimesh Supporter Subscriber")
          ]

        # Placeholder for GCT
        false ->
          [
            class: "text-success",
            "data-toggle": "tooltip",
            title: gettext("Glimesh Community Team")
          ]

        true ->
          [class: "text-white"]
      end

    default_tags = [
      to: Routes.user_profile_path(GlimeshWeb.Endpoint, :index, user.username),
      target: "_blank"
    ]

    Phoenix.HTML.Link.link(user.displayname, default_tags ++ tags)
  end

  def render_avatar(user) do
    tags =
      cond do
        user.is_admin ->
          [class: "avatar-ring platform-admin-ring"]

        Payments.is_platform_founder_subscriber?(user) ->
          [class: "avatar-ring avatar-animated-ring platform-founder-ring"]

        Payments.is_platform_supporter_subscriber?(user) ->
          [class: "avatar-ring platform-supporter-ring"]

        true ->
          [class: "avatar-ring"]
      end

    Tag.content_tag(
      :div,
      Tag.img_tag(
        Glimesh.Avatar.url({user.avatar, user}, :original),
        height: "20",
        width: "20"
      ),
      tags
    )
  end

  def render_username_and_avatar(user) do
    [render_avatar(user), " ", render_username(user)]
  end

  def render_channel_badge(channel, user) do
    cond do
      channel.user_id == user.id ->
        Tag.content_tag(:span, "Streamer", class: "badge badge-info")

      Glimesh.Chat.is_moderator?(channel, user) ->
        Tag.content_tag(:span, "Mod", class: "badge badge-info")

      Payments.is_subscribed?(channel, user) ->
        Tag.content_tag(:span, Tag.content_tag(:i, "", class: "fas fa-trophy"),
          class: "badge badge-secondary",
          "data-toggle": "tooltip",
          title: gettext("Channel Subscriber")
        )

      true ->
        ""
    end
  end

  def user_in_message(nil, _msg) do
    false
  end

  def user_in_message(user, chat_message) do
    username = user.username

    !(username == chat_message.user.username) &&
      (String.match?(chat_message.message, ~r/\b#{username}\b/i) ||
         String.match?(chat_message.message, ~r/\b#{"@" <> username}\b/i))
  end
end
