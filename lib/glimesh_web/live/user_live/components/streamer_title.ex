defmodule GlimeshWeb.UserLive.Components.StreamerTitle do
  use GlimeshWeb, :live_view

  alias Glimesh.Streams

  @impl true
  def render(assigns) do
    ~L"""
    <%= if @user && @is_streamer do %>
      <%= if !@editing do %>
        <h5 class=""><span class="badge badge-danger">Live!</span> <span class="badge badge-primary"><%= @metadata.category.tag_name %></span> <%= @metadata.stream_title %> <a class="fas fa-edit" phx-click="toggle-edit" href="#"></a></h5>
      <% else %>
        <%= f = form_for @changeset, "#", [phx_submit: :save] %>
          <div class="input-group">

          <%= select f, :category_id, @categories, [class: "form-control", "phx-hook": "Choices", "phx-update": "ignore"] %>
          <%= text_input f, :stream_title, [class: "form-control"] %>

          <div class="input-group-append">
            <%= submit dgettext("streams", "Save Info"), class: "btn btn-primary" %>
          </div>

          </div>
        </form
      <% end %>
    <% else %>
      <h5 class=""><span class="badge badge-danger">Live!</span> <span class="badge badge-primary"><%= @metadata.category.tag_name %></span> <%= @metadata.stream_title %> </h5>
    <% end %>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil}, socket) do
    if connected?(socket), do: Streams.subscribe_to(:metadata, streamer.id)
    metadata = Streams.get_metadata_from_streamer(streamer)

    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:user, nil)
     |> assign(:metadata, metadata)
     |> assign(:editing, false)
     |> assign(:is_streamer, false)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user}, socket) do
    if connected?(socket), do: Streams.subscribe_to(:metadata, streamer.id)
    metadata = Streams.get_metadata_from_streamer(streamer)

    {:ok,
     socket
     |> assign_categories()
     |> assign(:streamer, streamer)
     |> assign(:user, user)
     |> assign(:metadata, metadata)
     |> assign(:changeset, Streams.change_metadata(metadata))
     |> assign(:is_streamer, if(user.username == streamer.username, do: true, else: false))
     |> assign(:editing, false)}
  end

  @impl true
  def handle_event("toggle-edit", _value, socket) do
    {:noreply, socket |> assign(:editing, socket.assigns.editing |> Kernel.not())}
  end

  @impl true
  def handle_event("save", %{"metadata" => metadata}, socket) do
    case Streams.update_metadata(socket.assigns.metadata, metadata) do
      {:ok, changeset} ->
        {:noreply,
         socket
         |> assign(:editing, false)
         |> assign(:changeset, Streams.change_metadata(changeset))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_info({:update_metadata, data}, socket) do
    {:noreply, assign(socket, metadata: data)}
  end

  defp assign_categories(socket) do
    socket
    |> assign(
      :categories,
      Streams.list_categories_for_select()
    )
  end
end
