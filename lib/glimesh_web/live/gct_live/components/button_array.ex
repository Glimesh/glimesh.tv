defmodule GlimeshWeb.GctLive.Components.ButtonArray do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.CommunityTeam

  @impl true
  def render(assigns) do
    ~L"""
    <%= live_redirect gettext("Edit Profile"), class: (if @can_edit_profile, do: "btn btn-primary", else: "btn btn-primary disabled"), to: Routes.gct_path(@socket, :edit_user_profile, @user.username) %>
    <%= live_redirect gettext("Edit User"), class: (if @can_edit_user, do: "btn btn-primary", else: "btn btn-primary disabled"), to: Routes.gct_path(@socket, :edit_user, @user.username) %>
    <%= unless @user.is_banned do %>
      <button class="btn btn-danger" phx-click="show_ban_modal" <%= unless @can_ban, do: "disabled" %> ><%= gettext("Ban User") %></button>
    <% else %>
      <button class="btn btn-danger" phx-click="unban_user" <%= unless @can_ban, do: "disabled" %> ><%= gettext("Unban User") %></button>
    <% end %>

    <%= if @show_ban do %>
      <div id="ban-modal" class="live-modal"
        phx-capture-click="hide_ban_modal"
        phx-window-keydown="hide_ban_modal"
        phx-key="escape"
        phx-target="#paymentModal2"
        phx-page-loading>
        <div class="modal-dialog" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title"><%= gettext("Ban User") %></h5>
              <button type="button" class="close" phx-click="hide_ban_modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>

            <div class="modal-body">
              <%= form_for :user, "#", [phx_submit: :ban] %>
              <div class="form-group ">
                <label for="banReason"><%= gettext("Ban Reason") %></label>
                <textarea rows="5" class="form-control" name="ban_reason" id="banReason" placeholder="A descriptive reason to why this user is being banned. This is required, if you don't provide one then the user will not be banned."></textarea>
              </div>

              <button class="btn btn-danger btn-block mt-4"><%= gettext("Ban User") %></button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  @impl true
  def mount(_params, %{"admin" => admin, "user" => user}, socket) do
    can_ban = Bodyguard.permit?(Glimesh.CommunityTeam, :can_ban, admin, user)

    can_edit_user =
      case Bodyguard.permit(Glimesh.CommunityTeam, :edit_user, admin, user),
        do:
          (
            :ok -> true
            {:error, :unauthorized} -> false
          )

    can_edit_user_profile =
      case Bodyguard.permit(Glimesh.CommunityTeam, :edit_user_profile, admin, user),
        do:
          (
            :ok -> true
            {:error, :unauthorized} -> false
          )

    {:ok,
     socket
     |> assign(:admin, admin)
     |> assign(:user, user)
     |> assign(:show_ban, false)
     |> assign(:can_ban, can_ban)
     |> assign(:can_edit_user, can_edit_user)
     |> assign(:can_edit_profile, can_edit_user_profile)}
  end

  @impl true
  def handle_event("ban", %{"ban_reason" => ban_reason}, socket) do
    {:ok, _} = Accounts.ban_user(socket.assigns.user, ban_reason)

    CommunityTeam.create_audit_entry(socket.assigns.admin, %{
      action: "banned",
      target: socket.assigns.user.username,
      verbose_required: false,
      more_details: "Ban reason: " <> ban_reason
    })

    {:noreply,
     socket
     |> assign(:show_ban, false)
     |> redirect(
       to: Routes.gct_path(socket, :username_lookup, query: socket.assigns.user.username)
     )}
  end

  @impl true
  def handle_event("unban_user", _value, socket) do
    {:ok, user} = Accounts.unban_user(socket.assigns.user)

    CommunityTeam.create_audit_entry(socket.assigns.admin, %{
      action: "unbanned",
      target: socket.assigns.user.username,
      verbose_required: false
    })

    {:noreply,
     socket
     |> assign(user: user)
     |> redirect(
       to: Routes.gct_path(socket, :username_lookup, query: socket.assigns.user.username)
     )}
  end

  @impl true
  def handle_event("show_ban_modal", _value, socket) do
    {:noreply, socket |> assign(:show_ban, true)}
  end

  @impl true
  def handle_event("hide_ban_modal", _value, socket) do
    {:noreply, socket |> assign(:show_ban, false)}
  end
end
