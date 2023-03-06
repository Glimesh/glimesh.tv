defmodule GlimeshWeb.ChannelSettings.AddonsLive do
  use GlimeshWeb, :settings_live_view

  alias Glimesh.Streams

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> put_page_title(gettext("Support Modal"))
     |> assign(:addons, Streams.change_addons(socket.assigns.channel))}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"channel" => attrs}, socket) do
    changeset =
      socket.assigns.channel
      |> Streams.change_addons(attrs)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, addons: changeset)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"channel" => attrs}, socket) do
    case Streams.update_addons(socket.assigns.current_user, socket.assigns.channel, attrs) do
      {:ok, channel} ->
        {:noreply,
         socket
         |> assign(:channel, channel)
         |> put_flash(:info, "Updated addons.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, addons: changeset)}
    end
  end
end
