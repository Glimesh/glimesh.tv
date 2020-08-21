defmodule GlimeshWeb.UserLive.Components.FollowButton do
  use GlimeshWeb, :live_view

  alias Glimesh.Streams

  @impl true
  def render(assigns) do
    ~L"""
    <%= if @user do %>
      <%= if @following do %>
        <button class="btn btn-primary btn-block" phx-click="unfollow"><%= gettext("Unfollow") %></button>
      <% else %>
        <button class="btn btn-primary btn-block" phx-click="follow" phx-throttle="5000"><%= gettext("Follow") %></button>
      <% end %>
    <% else %>
      <%= link to: Routes.user_registration_path(@socket, :new), class: "btn btn-primary btn-block" do %>
        <%= gettext("Follow") %>
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
    following = Streams.is_following?(streamer, user)
    Gettext.put_locale(user.locale)

    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:user, user)
     |> assign(:following, following)}
  end

  @impl true
  def handle_event("follow", _value, socket) do
    case Streams.follow(socket.assigns.streamer, socket.assigns.user, false) do
      {:ok, _follow} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("User followed successfully"))
         |> assign(:following, true)}

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
         |> assign(:following, false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
