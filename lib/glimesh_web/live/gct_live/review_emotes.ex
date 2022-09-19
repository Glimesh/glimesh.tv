defmodule GlimeshWeb.GctLive.ReviewEmotes do
  use GlimeshWeb, :live_view

  alias Glimesh.Emotes

  @impl true
  def mount(_, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    user = Glimesh.Accounts.get_user_by_session_token(session["user_token"])

    pending_emotes = Emotes.list_pending_emotes()

    {:ok,
     socket
     |> assign(:user, user)
     |> assign(:pending_emotes, pending_emotes)}
  end

  @impl Phoenix.LiveView
  def handle_event("approve_emote_sub_only", %{"id" => id}, socket) do
    emote = Emotes.get_emote_by_id(id)

    case Emotes.approve_emote_sub_only(
           socket.assigns.user,
           emote,
           "#{emote.emote} is unable to be used platform wide. Please reach out to support@glimesh.tv for more information"
         ) do
      {:ok, _emote} ->
        {:noreply,
         socket
         |> put_flash(:info, "Approved for subscriber only and general use #{emote.emote}")
         |> assign(:pending_emotes, Emotes.list_pending_emotes())}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Error approving #{emote.emote}")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("approve_emote", %{"id" => id}, socket) do
    emote = Emotes.get_emote_by_id(id)

    case Emotes.approve_emote(socket.assigns.user, emote) do
      {:ok, _emote} ->
        {:noreply,
         socket
         |> put_flash(:info, "Approved for all use #{emote.emote}")
         |> assign(:pending_emotes, Emotes.list_pending_emotes())}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Error approving #{emote.emote}")}
    end
  end

  @impl Phoenix.LiveView
  def handle_event("reject_emote", %{"id" => id}, socket) do
    emote = Emotes.get_emote_by_id(id)

    case Emotes.reject_emote(
           socket.assigns.user,
           emote,
           "Emotes must abide by the Terms of Service and Rules of Conduct."
         ) do
      {:ok, _emote} ->
        {:noreply,
         socket
         |> put_flash(:info, "Rejected #{emote.emote}")
         |> assign(:pending_emotes, Emotes.list_pending_emotes())}

      {:error, _} ->
        {:noreply, socket |> put_flash(:error, "Error rejecting #{emote.emote}")}
    end
  end
end
