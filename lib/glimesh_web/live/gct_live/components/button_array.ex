defmodule GlimeshWeb.GctLive.Components.ButtonArray do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts

  @impl true
  def render(assigns) do
    ~L"""
    <%= live_redirect gettext("Edit Profile"), class: (if Glimesh.CommunityTeam.can_edit_user(@admin), do: "btn btn-primary", else: "btn btn-primary disabled"), to: Routes.gct_path(@socket, :edit_user_profile, @user.username) %>
    <%= live_redirect gettext("Edit User"), class: (if Glimesh.CommunityTeam.can_edit_user_profile(@admin), do: "btn btn-primary", else: "btn btn-primary disabled"), to: Routes.gct_path(@socket, :edit_user, @user.username) %>
    <%= unless @user.is_banned do %>
      <button class="btn btn-danger" phx-click="show_ban_modal"><%= gettext("Ban User") %></button>
    <%= else %>
      <button class="btn btn-danger" phx-click="unban_user"><%= gettext("Unban User") %></button>
    <% end %>
    <button class="btn btn-danger"><%= gettext("Delete User") %></button>

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
    {:ok,
     socket
     |> assign(:admin, admin)
     |> assign(:user, user)
     |> assign(:show_ban, false)}
  end

  @impl true
  def handle_event("ban", %{"ban_reason" => ban_reason}, socket) do
    {:ok, _} = Accounts.ban_user(socket.assigns.user, ban_reason)
    {:noreply,
     socket |> assign(:show_ban, false) |> put_flash(:info, "User has been banned!")}
  end

  @impl true
  def handle_event("unban_user", _value, socket) do
    {:ok, user} = Accounts.unban_user(socket.assigns.user)
    {:noreply,
     socket |> assign(user: user) |> put_flash(:info, "User has been unbanned!")}
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
