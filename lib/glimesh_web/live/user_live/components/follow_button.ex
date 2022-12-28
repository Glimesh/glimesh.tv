defmodule GlimeshWeb.UserLive.Components.FollowButton do
  use GlimeshWeb, :live_component

  alias Glimesh.AccountFollows

  alias Glimesh.Accounts.User
  alias Glimesh.AccountFollows.Follower

  def preload(list_of_assigns) do
    Enum.map(list_of_assigns, fn assigns ->
      Map.put(assigns, :following, following_or_empty(assigns.streamer, assigns.user))
    end)
  end

  def render(assigns) do
    ~H"""
    <div id={@id}>
      <%= if @user do %>
        <%= if @following do %>
          <div class="btn-group" role="group">
            <button
              class="btn btn-primary follow-button btn-responsive"
              phx-click="unfollow"
              phx-target={@myself}
              data-confirm={gettext("Are you sure?")}
            >
              <span class="d-none d-lg-block"><%= gettext("Unfollow") %></span>
              <span class="d-lg-none"><i class="fas fa-user-minus fa-fw"></i></span>
            </button>
            <%= if @following.has_live_notifications do %>
              <button
                type="button"
                class="btn btn-primary live-notifications-button btn-responsive"
                phx-click="disable_live_notifications"
                phx-target={@myself}
              >
                <i class="fas fa-bell fa-fw"></i>
              </button>
            <% else %>
              <button
                type="button"
                class="btn btn-primary live-notifications-button btn-responsive"
                phx-click="enable_live_notifications"
                phx-target={@myself}
              >
                <i class="far fa-bell fa-fw"></i>
              </button>
            <% end %>
          </div>
        <% else %>
          <button
            class="btn btn-primary follow-button btn-responsive"
            phx-click="follow"
            phx-target={@myself}
            phx-throttle="5000"
          >
            <span class="d-none d-lg-block"><%= gettext("Follow") %></span>
            <span class="d-lg-none"><i class="fas fa-user-plus fa-fw"></i></span>
          </button>
        <% end %>
      <% else %>
        <%= link to: Routes.user_registration_path(@socket, :new), class: "btn btn-primary btn-responsive" do %>
          <span class="d-none d-lg-block"><%= gettext("Follow") %></span>
          <span class="d-lg-none"><i class="fas fa-user-plus fa-fw"></i></span>
        <% end %>
      <% end %>
    </div>
    """
  end

  @impl true
  def handle_event("follow", _value, socket) do
    case AccountFollows.follow(socket.assigns.streamer, socket.assigns.user, false) do
      {:ok, following} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("User followed successfully"))
         |> assign(:following, following)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("unfollow", _value, socket) do
    case AccountFollows.unfollow(socket.assigns.streamer, socket.assigns.user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("User unfollowed successfully"))
         |> assign(:following, nil)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("enable_live_notifications", _value, socket) do
    case AccountFollows.update_following(socket.assigns.following, %{
           has_live_notifications: true
         }) do
      {:ok, following} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Enabled channel notifications"))
         |> assign(:following, following)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("disable_live_notifications", _value, socket) do
    case AccountFollows.update_following(socket.assigns.following, %{
           has_live_notifications: false
         }) do
      {:ok, following} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Disabled channel notifications"))
         |> assign(:following, following)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp following_or_empty(%User{} = streamer, %User{} = user) do
    AccountFollows.get_following(streamer, user)
  end

  defp following_or_empty(_, _) do
    %Follower{}
  end
end
