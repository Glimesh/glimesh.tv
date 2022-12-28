defmodule GlimeshWeb.Components.UserEffects do
  use GlimeshWeb, :component

  attr :user, Glimesh.Accounts.User, required: true

  def avatar_and_displayname(assigns) do
    ~H"""
    <span><.avatar user={@user} class="inline" /> <.displayname user={@user} /></span>
    """
  end

  attr :user, Glimesh.Accounts.User, required: true

  def displayname(assigns) do
    ~H"""
    <span><%= @user.displayname %></span>
    """
  end

  attr :user, Glimesh.Accounts.User, required: true
  attr :class, :string, default: ""

  def avatar(assigns) do
    ~H"""
    <img
      src={Glimesh.Avatar.url({@user.avatar, @user}, :original)}
      alt={@user.displayname}
      width="48"
      height="48"
      class={
        [
          "rounded-full",
          if(Glimesh.Accounts.can_receive_payments?(@user),
            do: "img-verified-streamer"
          ),
          @class
        ]
      }
    />
    """
  end

  attr :user, Glimesh.Accounts.User, required: true
  attr :twitter, Glimesh.Accounts.UserSocial, default: nil

  def social_icons(assigns) do
    ~H"""
    <%= if @twitter do %>
      <a
        href={"https://twitter.com/#{@twitter.username}"}
        rel="ugc"
        target="_blank"
        title={gettext("Linked Twitter Account @%{username}", username: @twitter.username)}
      >
        <span class="fa-stack">
          <i class="fas fa-certificate fa-stack-2x"></i>
          <i class="fab fa-twitter fa-stack-1x" style="color:white"></i>
        </span>
      </a>
    <% else %>
      <%= if @user.social_twitter do %>
        <a
          href={"https://twitter.com/#{@user.social_twitter}"}
          rel="ugc"
          target="_blank"
          class="social-icon"
        >
          <i class="fab fa-twitter"></i>
        </a>
      <% end %>
    <% end %>

    <%= if @user.social_youtube do %>
      <a
        href={"https://youtube.com/#{@user.social_youtube}"}
        rel="ugc"
        target="_blank"
        class="social-icon"
      >
        <i class="fab fa-youtube"></i>
      </a>
    <% end %>
    <%= if @user.social_instagram do %>
      <a
        rel="ugc"
        href={"https://instagram.com/#{@user.social_instagram}"}
        target="_blank"
        class="social-icon"
      >
        <i class="fab fa-instagram"></i>
      </a>
    <% end %>
    <%= if @user.social_discord do %>
      <a
        rel="ugc"
        href={"https://discord.gg/#{@user.social_discord}"}
        target="_blank"
        class="social-icon"
      >
        <i class="fab fa-discord"></i>
      </a>
    <% end %>
    <%= if @user.social_guilded do %>
      <a
        rel="ugc"
        href={"https://guilded.gg/#{@user.social_guilded}"}
        target="_blank"
        class="social-icon"
      >
        <i class="fab fa-guilded"></i>
      </a>
    <% end %>
    """
  end
end
