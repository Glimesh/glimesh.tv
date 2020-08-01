defmodule GlimeshWeb.UserLive.SubscribeButton do
  use GlimeshWeb, :live_view

  @impl true
  def render(assigns) do
    ~L"""
      <%= if @user do %>
        <%= if @subscribed do %>
          <button class="btn btn-secondary" phx-click="unsubscribe">Unsubscribe</button>
        <% else %>
          <button class="btn btn-secondary" phx-click="subscribe" phx-throttle="50000">Subscribe</button>
        <% end %>
      <% else %>
        <%= link "Subscribe", to: Routes.user_registration_path(@socket, :new), class: "btn btn-secondary" %>
      <% end %>
      """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil}, socket) do
    {:ok, socket |> assign(:streamer, streamer) |> assign(:user, nil) |> assign(:subscribed, false)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user}, socket) do
    subscribed = false # Glimesh.Streams.is_following?(streamer, user)

    {:ok, socket
          |> assign(:streamer, streamer)
          |> assign(:user, user)
          |> assign(:subscribed, subscribed)}
  end

  def handle_event("subscribe", value, socket) do
    case Glimesh.Streams.follow(socket.assigns.streamer, socket.assigns.user, false) do
      {:ok, _follow} ->
        {:noreply,
          socket
          |> put_flash(:info, "User followed successfully")
          |> assign(:following, true)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset) |> IO.inspect()}
    end
  end

  def handle_event("unsubscribe", _value, socket) do
    case Glimesh.Streams.unfollow(socket.assigns.streamer, socket.assigns.user) do
      {:ok, _} ->
        {:noreply,
          socket
          |> put_flash(:info, "User unfollowed successfully")
          |> assign(:following, false)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
