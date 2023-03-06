defmodule GlimeshWeb.ChannelSettings.EmotesLive do
  use GlimeshWeb, :settings_live_view

  alias Glimesh.Emotes

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    static_emotes = Emotes.list_static_emotes_for_channel(socket.assigns.channel)
    animated_emotes = Emotes.list_animated_emotes_for_channel(socket.assigns.channel)
    submitted_emotes = Emotes.list_submitted_emotes_for_channel(socket.assigns.channel)

    if length(static_emotes ++ animated_emotes ++ submitted_emotes) > 0 do
      {:ok,
       socket
       |> put_page_title(gettext("Channel Emotes"))
       |> assign(:static_emotes, static_emotes)
       |> assign(:animated_emotes, animated_emotes)
       |> assign(:submitted_emotes, submitted_emotes)}
    else
      {:ok, redirect(socket, to: ~p"/users/settings/upload_emotes")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete_emote", %{"id" => id}, socket) do
    emote = Emotes.get_emote_by_id(id)

    case Emotes.delete_emote(socket.assigns.current_user, emote) do
      {:ok, _emote} ->
        {:noreply,
         socket
         |> put_flash(:emote_info, "Deleted #{emote.emote}")
         |> redirect(to: ~p"/users/settings/emotes")}

      {:error, _} ->
        {:noreply, socket |> put_flash(:emote_error, "Error deleting #{emote.emote}")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("save_emote_options", %{"nothing" => params}, socket) do
    emote = Emotes.get_emote_by_id(params["emote_id"])

    if params["allow_global_usage"] == "true" do
      Emotes.clear_global_emotes(socket.assigns.current_user, emote)
    end

    case Emotes.save_emote_options(socket.assigns.current_user, emote, params) do
      {:ok, _emote} ->
        {:noreply,
         socket
         |> put_flash(:emote_info, "Changes made successfully")
         |> redirect(to: ~p"/users/settings/emotes")}

      {:error, _} ->
        {:noreply, socket |> put_flash(:emote_error, "Error updating #{emote.emote}")}
    end
  end
end
