defmodule GlimeshWeb.UserLive.Components.FollowButton do
  use GlimeshWeb, :live_view

  alias Glimesh.Streams

  @impl true
  def render(assigns) do
    ~L"""
    <%= if @user do %>
      <%= if @following do %>
        <div class="btn-group" role="group">
          <button class="btn btn-primary btn-block follow-button" phx-click="unfollow"><span class="uf_txt"><%= gettext("Unfollow") %></span><span class="uf_ico"><i class="fas fa-user-minus"></i></span></button>
          <%= if @following.has_live_notifications do %>
          <button type="button" class="btn btn-primary live-notifications-button" phx-click="disable_live_notifications"><i class="fas fa-bell"></i></button>
          <% else %>
          <button type="button" class="btn btn-primary live-notifications-button" phx-click="enable_live_notifications"><i class="far fa-bell"></i></button>
          <% end %>
        </div>
      <% else %>
        <button class="btn btn-primary btn-block follow-button" phx-click="follow" phx-throttle="5000"><span class="f_txt"><%= gettext("Follow") %></span><span class="f_ico"><i class="fas fa-user-plus"></i></span></button>
      <% end %>
    <% else %>
      <%= link to: Routes.user_registration_path(@socket, :new), class: "btn btn-primary btn-block" do %>
      <span class="f_txt"><%= gettext("Follow") %></span><span class="f_ico"><i class="fas fa-user-plus"></i></span>
      <% end %>
    <% end %>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil}, socket) do
    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:user, nil)
     |> assign(:following, false)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user}, socket) do
    Gettext.put_locale(user.locale)

    following = Streams.get_following(streamer, user)

    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:user, user)
     |> assign(:following, following)}
  end

  @impl true
  def handle_event("follow", _value, socket) do
    case Streams.follow(socket.assigns.streamer, socket.assigns.user, false) do
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
    case Streams.unfollow(socket.assigns.streamer, socket.assigns.user) do
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
    case Streams.update_following(socket.assigns.following, %{
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
    case Streams.update_following(socket.assigns.following, %{
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
end
