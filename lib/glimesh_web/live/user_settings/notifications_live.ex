defmodule GlimeshWeb.NotificationsLive do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Streams

  @impl true
  def mount(_params, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    user = Accounts.get_user_by_session_token(session["user_token"])

    changeset = Accounts.change_user_notifications(user)
    channel_live_subscriptions = Glimesh.Streams.list_followed_live_notification_channels(user)
    email_log = Glimesh.Emails.list_email_log(user)

    {:ok,
     socket
     |> put_page_title("Notifications")
     |> assign(:email_log, email_log)
     |> assign(:changeset, changeset)
     |> assign(:channel_live_subscriptions, channel_live_subscriptions)
     |> assign(:current_user, user)}
  end

  @impl true
  def handle_event("remove_live_notification", %{"streamer" => streamer_id}, socket) do
    streamer = Accounts.get_user!(streamer_id)
    following = Streams.get_following(streamer, socket.assigns.current_user)

    case Streams.update_following(following, %{
           has_live_notifications: false
         }) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           gettext("Disabled live channel notifications for %{streamer}",
             streamer: streamer.displayname
           )
         )
         |> assign(
           :channel_live_subscriptions,
           Glimesh.Streams.list_followed_live_notification_channels(socket.assigns.current_user)
         )}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_event("save", %{"user" => user_params}, socket) do
    case Glimesh.Accounts.update_user_notifications(socket.assigns.current_user, user_params) do
      {:ok, user} ->
        {:noreply,
         socket
         |> assign(:changeset, Accounts.change_user_notifications(user))
         |> assign(:current_user, user)
         |> put_flash(:info, gettext("Saved notification preferences."))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end
end
