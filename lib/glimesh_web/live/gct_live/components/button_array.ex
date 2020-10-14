defmodule GlimeshWeb.GctLive.Components.ButtonArray do
  use GlimeshWeb, :live_view

  @impl true
  def render(assigns) do
    ~L"""
    <%= live_redirect gettext("Edit Profile"), class: (if Glimesh.CommunityTeam.can_edit_user(@admin), do: "btn btn-primary", else: "btn btn-primary disabled"), to: Routes.gct_path(@socket, :edit_user_profile, @user.username) %>
    <%= live_redirect gettext("Edit User"), class: (if Glimesh.CommunityTeam.can_edit_user_profile(@admin), do: "btn btn-primary", else: "btn btn-primary disabled"), to: Routes.gct_path(@socket, :edit_user, @user.username) %>
    <button class="btn btn-danger"><%= gettext("Ban User") %></button>
    <button class="btn btn-danger"><%= gettext("Delete User") %></button>
    """
  end

  @impl true
  def mount(_params, %{"admin" => admin, "user" => user}, socket) do
    {:ok,
     socket
     |> assign(:admin, admin)
     |> assign(:user, user)}
  end

end
