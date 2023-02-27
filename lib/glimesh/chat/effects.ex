defmodule Glimesh.Chat.Effects do
  @moduledoc """
  Chat effects for rendering badges, usernames, etc.
  """

  use GlimeshWeb, :verified_routes

  import GlimeshWeb.Gettext

  alias Glimesh.Payments
  alias Phoenix.HTML.Tag

  alias Glimesh.Chat.Effects.Badges.{
    ChannelSubscriberBadge,
    ModeratorBadge,
    StreamerBadge
  }

  alias Glimesh.Chat.ChatMessage, as: Message
  alias Glimesh.Chat.ChatMessage.Metadata

  def render_global_badge(_user) do
    # if user.is_admin do
    #   Tag.content_tag(:span, "Team Glimesh", class: "badge badge-danger")
    # else
    #   ""
    # end

    ""
  end

  def get_username_color(user, default \\ "text-color-link") do
    cond do
      user.is_admin -> "text-danger"
      user.is_gct -> "text-primary"
      user.is_community_champion -> "text-success"
      user.is_events_team -> "EventsTeam_Font"
      Payments.is_platform_founder_subscriber?(user) -> "text-warning"
      true -> default
    end
  end

  def get_username_color_for_message(
        %Message{user: user, metadata: metadata},
        default \\ "text-color-link"
      ) do
    cond do
      user.is_admin -> "text-danger"
      user.is_gct -> "text-primary"
      user.is_community_champion -> "text-success"
      metadata.platform_founder_subscriber -> "text-warning"
      true -> default
    end
  end

  def render_username(%Message{user: user, metadata: metadata} = message) do
    tags =
      cond do
        user.is_admin ->
          [
            "data-toggle": "tooltip",
            title: gettext("Glimesh Staff")
          ]

        user.is_gct ->
          [
            "data-toggle": "tooltip",
            title: gettext("Core Team")
          ]

        user.is_community_champion ->
          [
            "data-toggle": "tooltip",
            title: gettext("Community Champion")
          ]

        metadata.platform_founder_subscriber ->
          [
            "data-toggle": "tooltip",
            title: gettext("Glimesh Gold Supporter Subscriber")
          ]

        metadata.platform_supporter_subscriber ->
          [
            "data-toggle": "tooltip",
            title: gettext("Glimesh Supporter Subscriber")
          ]

        true ->
          []
      end

    color_class = [class: get_username_color_for_message(message)]

    default_tags = [
      to: ~p"/#{user.username}",
      target: "_blank"
    ]

    Phoenix.HTML.Link.link(user.displayname, default_tags ++ color_class ++ tags)
  end

  def render_avatar(%Message{metadata: metadata, user: user}) do
    tags =
      cond do
        user.is_admin ->
          [class: "avatar-ring platform-admin-ring"]

        metadata.platform_founder_subscriber ->
          [class: "avatar-ring avatar-animated-ring platform-founder-ring"]

        metadata.platform_supporter_subscriber ->
          [class: "avatar-ring platform-supporter-ring"]

        true ->
          [class: "avatar-ring"]
      end

    Tag.content_tag(
      :div,
      Tag.img_tag(
        Glimesh.Avatar.url({user.avatar, user}, :original),
        height: "20",
        width: "20",
        alt: user.displayname
      ),
      tags
    )
  end

  def render_username_and_avatar(%Message{metadata: %Metadata{}} = message) do
    [render_avatar(message), " ", render_username(message)]
  end

  def render_username_and_avatar(%Message{user: user} = message) do
    # Backwards compatibility
    message =
      Map.put(
        message,
        :metadata,
        Map.merge(Metadata.defaults(), %{
          platform_founder_subscriber: Payments.is_platform_founder_subscriber?(user),
          platform_supporter_subscriber: Payments.is_platform_supporter_subscriber?(user)
        })
      )

    [render_avatar(message), " ", render_username(message)]
  end

  @doc """
  Renders channel badges based on message metadata
  """
  def render_channel_badge(%Message{metadata: %Metadata{streamer: true}}) do
    StreamerBadge.render()
  end

  def render_channel_badge(%Message{metadata: %Metadata{subscriber: true, moderator: true}}) do
    [ModeratorBadge.render(), " ", ChannelSubscriberBadge.render()]
  end

  def render_channel_badge(%Message{metadata: %Metadata{moderator: true}}) do
    ModeratorBadge.render()
  end

  def render_channel_badge(%Message{metadata: %Metadata{subscriber: true}}) do
    ChannelSubscriberBadge.render()
  end

  def render_channel_badge(%Message{metadata: %Metadata{admin: true}}), do: ""
  def render_channel_badge(%Message{metadata: nil}), do: nil
  def render_channel_badge(%Message{metadata: %Metadata{} = _metadata}), do: nil

  def render_channel_badge(channel, user) do
    cond do
      channel.user_id == user.id ->
        StreamerBadge.render()

      Glimesh.Chat.is_moderator?(channel, user) and Payments.is_subscribed?(channel, user) ->
        [ModeratorBadge.render(), " ", ChannelSubscriberBadge.render()]

      Glimesh.Chat.is_moderator?(channel, user) ->
        ModeratorBadge.render()

      Payments.is_subscribed?(channel, user) ->
        ChannelSubscriberBadge.render()

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
