defmodule GlimeshWeb.UserLive.Components.StreamerTitle do
  use GlimeshWeb, :live_view

  alias Glimesh.Presence

  @impl true
  def render(assigns) do
    ~L"""
    <h5 class=""><span class="badge badge-danger">Live!</span> <%= @title %></h5>
    <%= if @user do %>
      <%= if @user.username == @streamer.username do %>
        <div class="btn-group mr-2" role="group" aria-label="Zero Group">
        <button class="btn btn-primary btn-block mt-1" phx-click="change-title"><%= dgettext("streams", "Change Title") %></span>
        </div>
      <% end %>
    <% end %>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil}, socket) do
    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:user, nil)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user}, socket) do
    IO.inspect(Glimesh.Streams.get_metadata_from_streamer(streamer).stream_title)
    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:user, user)
     |> assign(:title, Glimesh.Streams.get_metadata_from_streamer(streamer).stream_title)}
  end

  @impl true
  def handle_event("change-title", _value, socket) do
    case Glimesh.Streams.change_title(socket.assigns.streamer, "Testing") do
      {:ok, _changetitle} ->
        {:noreply, socket |> put_flash(:info, "Title updated!")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end

  end

end
