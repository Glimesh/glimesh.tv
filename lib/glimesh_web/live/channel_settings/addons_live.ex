defmodule GlimeshWeb.ChannelSettings.AddonsLive do
  use GlimeshWeb, :live_view

  alias Glimesh.Streams

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    changeset = Streams.change_addons(socket.assigns.channel)

    {:ok,
     socket
     |> put_page_title(gettext("Support Modal"))
     |> assign(form: to_form(changeset))}
  end

  @impl Phoenix.LiveView
  def handle_event("validate", %{"channel" => attrs}, socket) do
    form =
      socket.assigns.channel
      |> Streams.change_addons(attrs)
      |> Map.put(:action, :update)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  @impl Phoenix.LiveView
  def handle_event("save", %{"channel" => attrs}, socket) do
    case Streams.update_addons(socket.assigns.current_user, socket.assigns.channel, attrs) do
      {:ok, channel} ->
        {:noreply,
         socket
         |> assign(channel: channel)
         |> put_flash(:info, "Updated addons.")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
