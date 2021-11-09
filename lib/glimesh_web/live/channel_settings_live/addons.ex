defmodule GlimeshWeb.ChannelSettingsLive.Addons do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.ChannelLookups
  alias Glimesh.Streams

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    streamer = Accounts.get_user_by_session_token(session["user_token"])

    case ChannelLookups.get_channel_for_user(streamer) do
      %Glimesh.Streams.Channel{} = channel ->
        {:ok,
         socket
         |> put_page_title(gettext("Support Modal"))
         |> assign(:site_theme, session["site_theme"])
         |> assign(:username, streamer.username)
         |> assign(:addons, Streams.change_addons(channel))
         |> assign(:user, streamer)
         |> assign(:channel, channel)}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
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
    case Streams.update_addons(socket.assigns.user, socket.assigns.channel, attrs) do
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
