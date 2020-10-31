defmodule GlimeshWeb.UserLive.Components.ChannelTitle do
  use GlimeshWeb, :live_view
  import Gettext, only: [with_locale: 2]

  alias Glimesh.Streams

  @impl true
  def render(assigns) do
    ~L"""
    <%= if @can_change do %>
      <%= if !@editing do %>
        <h5><%= render_badge(@channel) %> <span class="badge badge-primary"><%= @channel.category.tag_name %></span> <%= @channel.title %> <a class="fas fa-edit" phx-click="toggle-edit" href="#" aria-label="<%= gettext("Edit") %>"></a></h5>
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
      <h5><%= render_badge(@channel) %> <span class="badge badge-primary"><%= @channel.category.tag_name %></span> <%= @channel.title %> </h5>
    <% end %>
    """
  end

  def render_badge(channel) do
    if channel.status == "live" do
      raw("""
      <span class="badge badge-danger">Live!</span>
      """)
    else
      raw("")
    end
  end

  @impl true
  def mount(_params, %{"channel_id" => channel_id, "user" => nil}, socket) do
    if connected?(socket), do: Streams.subscribe_to(:channel, channel_id)
    channel = Streams.get_channel!(channel_id)

    {:ok,
     socket
     |> assign(:channel, channel)
     |> assign(:user, nil)
     |> assign(:channel, channel)
     |> assign(:editing, false)
     |> assign(:can_change, false)}
  end

  @impl true
  def mount(_params, %{"channel_id" => channel_id, "user" => user}, socket) do
    if connected?(socket), do: Streams.subscribe_to(:channel, channel_id)
    channel = Streams.get_channel!(channel_id)

    {:ok,
     socket
     |> assign_categories()
     |> assign(:channel, channel)
     |> assign(:user, user)
     |> assign(:channel, channel)
     |> assign(:changeset, Streams.change_channel(channel))
     |> assign(:can_change, Streams.can_change_channel?(channel, user))
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
         |> assign(:channel, changeset)
         |> assign(:changeset, Streams.change_channel(changeset))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_info({:channel, data}, socket) do
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
