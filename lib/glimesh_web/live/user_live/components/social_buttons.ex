defmodule GlimeshWeb.UserLive.Components.SocialButtons do
  use GlimeshWeb, :live_view

  @impl true
  def render(assigns) do
    ~L"""
    <%= if @twitter_social  do %>
    <li rel="ugc" class="list-inline-item" data-toggle="tooltip"
        title="<%= gettext("Linked Twitter Account @%{username}", username: @twitter_social.username) %>">
        <a href="https://twitter.com/<%= @twitter_social.username %>" target="_blank">
            <span class="fa-stack">
                <i class="fas fa-certificate fa-stack-2x"></i>
                <i class="fab fa-twitter fa-stack-1x" style="color:white"></i>
            </span>
        </a>
    </li>
    <% else %>
    <%= if @streamer.social_twitter do %>
    <li rel="ugc" class="list-inline-item">
        <a href="https://twitter.com/<%= @streamer.social_twitter %>" target="_blank"
            class="social-icon">
            <i class="fab fa-twitter"></i>
        </a>
    </li>
    <% end %>
    <% end %>

    <%= if @streamer.social_youtube do %>
    <li rel="ugc" class="list-inline-item">
        <a href="https://youtube.com/<%= @streamer.social_youtube %>" target="_blank"
            class="social-icon">
            <i class="fab fa-youtube"></i>
        </a>
    </li>
    <%  end %>
    <%= if @streamer.social_instagram do %>
    <li class="list-inline-item">
        <a rel="ugc" href="https://instagram.com/<%= @streamer.social_instagram %>" target="_blank"
            class="social-icon">
            <i class="fab fa-instagram"></i>
        </a>
    </li>
    <%  end %>
    <%= if @streamer.social_discord do %>
    <li class="list-inline-item">
        <a rel="ugc" href="https://discord.gg/<%= @streamer.social_discord %>" target="_blank"
            class="social-icon">
            <i class="fab fa-discord"></i>
        </a>
    </li>
    <% end %>
    <%= if @streamer.social_guilded do %>
    <li class="list-inline-item">
        <a rel="ugc" href="https://guilded.gg/<%= @streamer.social_guilded %>" target="_blank"
            class="social-icon">
            <i class="fab fa-guilded"></i>
        </a>
    </li>
    <% end %>
    """
  end

  @impl true
  def mount(_params, %{"user_id" => user_id}, socket) do
    user = Glimesh.Accounts.get_user!(user_id)

    {:ok,
     socket
     |> assign(:twitter_social, Glimesh.Socials.get_social(user, "twitter"))
     |> assign(:streamer, user)}
  end
end
