defmodule GlimeshWeb.UserLive.Components.UnhostButton do
  use GlimeshWeb, :live_view

  alias Glimesh.ChannelLookups
  alias Glimesh.Streams


  @impl true
  def render(assigns) do
    ~L"""
      <%= if @can_unhost do %>
      <button class="btn btn-danger btn-responsive" data-toggle="tooltip" phx-click="unhost"><%= gettext("Unhost")%></button>
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
      |> assign(:can_unhost, false)
      |> assign(:channel, channel)}

  end

  @impl true
  def mount(_params, %{"channel_id" => channel_id, "user" => user} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])
    if connected?(socket), do: Streams.subscribe_to(:channel, channel_id)
    channel = ChannelLookups.get_channel!(channel_id)


    {:ok,
      socket
      |> assign(:can_unhost, Bodyguard.permit?(Glimesh.Streams, :update_channel, user, channel))
      |> assign(:channel, channel)
      |> assign(:user, user)}
  end

  @impl true
  def handle_event("unhost", _value, socket) do
    unhost_attrs = %{is_hosting: false, hosted_channel_id: nil}
    case Streams.update_channel(socket.assigns.user, socket.assigns.channel, unhost_attrs) do
      {:ok, channel} ->
        {:noreply,
          socket
          |> assign(:channel, channel)}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_info({:channel, channel}, socket) do
    {:noreply, assign(socket, channel: channel)}
  end

end
