defmodule GlimeshWeb.UserLive.Components.HostButton do
  use GlimeshWeb, :live_view

  alias Glimesh.ChannelLookups
  alias Glimesh.Streams


  @impl true
  def render(assigns) do
    ~L"""
      <%= if @can_host do %>
      <button class="btn btn-success btn-responsive" data-toggle="tooltip" phx-click="host"><%= gettext("Host")%></button>
      <% end %>
    """
  end

  @impl true
  def mount(_params, %{"channel_id" => channel_id, "user" => nil} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])
    if connected?(socket), do: Streams.subscribe_to(:channel, channel_id)
    channel = ChannelLookups.get_channel!(channel_id)

    {:ok,
      socket
      |> assign(:channel, channel)
      |> assign(:can_host, false)}

  end

  @impl true
  def mount(_params, %{"channel_id" => channel_id, "user" => user} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])
    if connected?(socket), do: Streams.subscribe_to(:channel, channel_id)
    channel = ChannelLookups.get_channel!(channel_id)


    {:ok,
      socket
      |> assign(:channel, channel)
      |> assign(:user, user)
      |> assign(:can_host, Bodyguard.permit?(Glimesh.Streams, :update_channel, user, channel))}
  end

  @impl true
  def handle_event("host", _value, socket) do
    host_attrs = %{is_hosting: true, hosted_channel_id: socket.assigns.channel.id}
    case Streams.update_channel(socket.assigns.user, ChannelLookups.get_channel_for_username(socket.assigns.user.username), host_attrs) do
      {:ok, channel} ->
        {:noreply,
          socket}
    end
  end

  @impl true
  def handle_info({:channel, channel}, socket) do
    {:noreply, socket}
  end

end
