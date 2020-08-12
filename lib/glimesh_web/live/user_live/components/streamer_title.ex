defmodule GlimeshWeb.UserLive.Components.StreamerTitle do
  use GlimeshWeb, :live_view

  alias Glimesh.Presence
  alias Glimesh.Streams.StreamMetadata

  @impl true
  def render(assigns) do
    ~L"""
    <%= if @user do %>
      <%= unless @user.username == @streamer.username do %>
        <h5 class=""><span class="badge badge-danger">Live!</span> <%= @title %></h5>
      <% else %>
        <%= if !@editing do %>
          <h5 class=""><span class="badge badge-danger">Live!</span> <%= @title %>  <a class="fas fa-edit" phx-click="toggle-edit" href="#"></a></h5>
        <% else %>
          <h5 class="">
            <div class="form-group">
              <%= f = form_for @changeset, "#", [phx_submit: :save] %>
              <%= text_input f, :stream_title, [class: "form-control"] %>
              <%= submit "Update Title", class: "btn btn-primary mt-1" %>
              <i class="far fa-edit" phx-click="toggle-edit" style="color: red"></i>
            </div>
          </h5>
        <% end %>
      <% end %>
    <% else %>
      <h5 class=""><span class="badge badge-danger">Live!</span> <%= @title %></h5>
    <% end %>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil}, socket) do
    if connected?(socket), do: Glimesh.Streams.subscribe_metadata()
    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:user, nil)
     |> assign(:title, Glimesh.Streams.get_metadata_from_streamer(streamer).stream_title)
     |> assign(:editing, false)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user}, socket) do
    if connected?(socket), do: Glimesh.Streams.subscribe_metadata()
    title_changeset = if streamer.username == user.username do
      Glimesh.Streams.StreamMetadata.changeset(Glimesh.Streams.get_metadata_from_streamer(streamer)
      |> Map.merge(%{streamer: streamer}))
    else
      nil
    end
    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:user, user)
     |> assign(:title, Glimesh.Streams.get_metadata_from_streamer(streamer).stream_title)
     |> assign(:changeset, title_changeset)
     |> assign(:editing, false)}
  end

  @impl true
  def handle_event("toggle-edit", _value, socket) do
    {:noreply, socket |> assign(:editing, socket.assigns.editing |> Kernel.not)}
  end

  @impl true
  def handle_event("save", value, socket) do
    case Glimesh.Streams.change_title(socket.assigns.streamer, value["stream_metadata"]["stream_title"]) do
      {:ok, changetitle} ->
        {:noreply,
        socket
        |> assign(:editing, false)
        |> assign(:title, value["stream_metadata"]["stream_title"])
        |> assign(:changeset, Glimesh.Streams.StreamMetadata.changeset(changetitle |> Map.merge(%{streamer: socket.assigns.streamer})))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_info({:update_title, data}, socket) do
    cond do
      data.streamer_username == socket.assigns.streamer.username -> {:noreply, assign(socket, title: data.title)}
      true -> {:noreply, socket}
    end
  end

end
