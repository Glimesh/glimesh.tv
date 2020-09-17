defmodule GlimeshWeb.UserLive.Components.StreamerTitle do
  use GlimeshWeb, :live_view
  import Gettext, only: [with_locale: 2]

  alias Glimesh.Streams

  @impl true
  def render(assigns) do
    ~L"""
    <%= if @user && @is_streamer do %>
      <%= if !@editing do %>
        <h5 class=""><span class="badge badge-danger">Live!</span> <span class="badge badge-primary"><%= @channel.category.tag_name %></span> <%= @channel.title %> <a class="fas fa-edit" phx-click="toggle-edit" href="#"></a></h5>
      <% else %>
        <%= f = form_for @changeset, "#", [phx_submit: :save] %>
          <div class="input-group">

          <%= select f, :category_id, @categories, [class: "form-control", "phx-hook": "Choices", "phx-update": "ignore"] %>
          <%= text_input f, :title, [class: "form-control"] %>

          <div class="input-group-append">
          <%= with_locale(@user.locale, fn -> %>
            <%= submit gettext("Save Info"), class: "btn btn-primary" %>
          <% end) %>
          </div>

          </div>
        </form>
      <% end %>
    <% else %>
      <h5 class=""><span class="badge badge-danger">Live!</span> <span class="badge badge-primary"><%= @channel.category.tag_name %></span> <%= @channel.title %> </h5>
    <% end %>
    """
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil}, socket) do
    if connected?(socket), do: Streams.subscribe_to(:channel, streamer.id)
    channel = Streams.get_channel_for_user!(streamer)

    {:ok,
     socket
     |> assign(:streamer, streamer)
     |> assign(:user, nil)
     |> assign(:channel, channel)
     |> assign(:editing, false)
     |> assign(:is_streamer, false)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user}, socket) do
    if connected?(socket), do: Streams.subscribe_to(:channel, streamer.id)
    channel = Streams.get_channel_for_username!(streamer.username)

    {:ok,
     socket
     |> assign_categories()
     |> assign(:streamer, streamer)
     |> assign(:user, user)
     |> assign(:channel, channel)
     |> assign(:changeset, Streams.change_channel(channel))
     |> assign(:is_streamer, if(user.username == streamer.username, do: true, else: false))
     |> assign(:editing, false)}
  end

  @impl true
  def handle_event("toggle-edit", _value, socket) do
    {:noreply, socket |> assign(:editing, socket.assigns.editing |> Kernel.not())}
  end

  @impl true
  def handle_event("save", %{"channel" => channel}, socket) do
    case Streams.update_channel(socket.assigns.channel, channel) do
      {:ok, changeset} ->
        {:noreply,
         socket
         |> assign(:editing, false)
         |> assign(:changeset, Streams.change_channel(changeset))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_info({:update_channel, data}, socket) do
    {:noreply, assign(socket, channel: data)}
  end

  defp assign_categories(socket) do
    socket
    |> assign(
      :categories,
      Streams.list_categories_for_select()
    )
  end
end
