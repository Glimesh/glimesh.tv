defmodule GlimeshWeb.ChannelSettingsLive.ChannelEmotes do
  use GlimeshWeb, :live_view

  alias Glimesh.Emotes

  @impl Phoenix.LiveView
  def mount(_, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    user = Glimesh.Accounts.get_user_by_session_token(session["user_token"])
    channel = Glimesh.ChannelLookups.get_channel_for_user(user)

    static_emotes = Emotes.list_static_emotes_for_channel(channel)
    animated_emotes = Emotes.list_animated_emotes_for_channel(channel)
    submitted_emotes = Emotes.list_submitted_emotes_for_channel(channel)

    if length(static_emotes ++ animated_emotes ++ submitted_emotes) > 0 do
      {:ok,
       socket
       |> put_page_title(gettext("Channel Emotes"))
       |> assign(:user, user)
       |> assign(:channel, channel)
       |> assign(:static_emotes, static_emotes)
       |> assign(:animated_emotes, animated_emotes)
       |> assign(:submitted_emotes, submitted_emotes)}
    else
      {:ok, redirect(socket, to: Routes.user_settings_path(socket, :upload_emotes))}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("delete_emote", %{"id" => id}, socket) do
    emote = Emotes.get_emote_by_id(id)

    case Emotes.delete_emote(socket.assigns.user, emote) do
      {:ok, _emote} ->
        {:noreply,
         socket
         |> put_flash(:emote_info, "Deleted #{emote.emote}")
         |> redirect(to: Routes.user_settings_path(socket, :emotes))}

      {:error, _} ->
        {:noreply, socket |> put_flash(:emote_error, "Error deleting #{emote.emote}")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("save_emote_options", %{"nothing" => params}, socket) do
    emote = Emotes.get_emote_by_id(params["emote_id"])

    if params["allow_global_usage"] == "true" do
      Emotes.clear_global_emotes(socket.assigns.user, emote)
    end

    case Emotes.save_emote_options(socket.assigns.user, emote, params) do
      {:ok, _emote} ->
        {:noreply,
         socket
         |> put_flash(:emote_info,"Changes made successfully")
         |> redirect(to: Routes.user_settings_path(socket, :emotes))}

      {:error, _} ->
        {:noreply, socket |> put_flash(:emote_error, "Error updating #{emote.emote}")}
      end
    end
  end
