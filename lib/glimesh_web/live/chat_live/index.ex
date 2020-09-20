defmodule GlimeshWeb.ChatLive.Index do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Chat
  alias Glimesh.Chat.ChatMessage
  alias Glimesh.Presence
  alias Glimesh.Streams

  @impl true
  def mount(_params, %{"streamer" => streamer} = session, socket) do
    if connected?(socket), do: Streams.subscribe_to(:chat, streamer.id)

    if session["user"] do
      user = session["user"]

      Presence.track_presence(
        self(),
        Streams.get_subscribe_topic(:chatters, streamer.id),
        user.id,
        %{
          typing: false,
          username: user.username,
          avatar: Glimesh.Avatar.url({user.avatar, user}, :original),
          user_id: user.id,
          size: 48
        }
      )
    end

    new_socket =
      socket
      |> assign(:update_action, "replace")
      |> assign(:streamer, streamer)
      |> assign(:user, session["user"])
      |> assign(:is_moderator, Glimesh.Chat.can_moderate?(streamer, session["user"]))
      |> assign(:chat_messages, list_chat_messages(streamer))
      |> assign(:chat_message, %ChatMessage{})
      |> assign(:chat_clear, false)

    {:ok, new_socket, temporary_assigns: [chat_messages: []]}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    chat_message = Chat.get_chat_message!(id)
    {:ok, _} = Chat.delete_chat_message(chat_message)

    {:noreply, assign(socket, :chat_messages, list_chat_messages(socket.assigns.streamer))}
  end

  @impl true
  def handle_event("timeout_user", %{"user" => to_ban_user}, socket) do
    dt = DateTime.add(DateTime.utc_now(), 300, :second) # for some reason add can only accept seconds and lower so this will equate to 5 minutes in the future
    Streams.timeout_user(
      socket.assigns.streamer,
      socket.assigns.user,
      Accounts.get_by_username!(to_ban_user),
      dt
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("ban_user", %{"user" => to_ban_user}, socket) do
    Streams.ban_user(
      socket.assigns.streamer,
      socket.assigns.user,
      Accounts.get_by_username!(to_ban_user)
    )

    {:noreply, assign(socket, :chat_messages, list_chat_messages(socket.assigns.streamer))}
  end

  @impl true
  def handle_info({:chat_sent, message}, socket) do
    {:noreply,
      socket
      |> assign(:update_action, "append")
      |> update(:chat_messages, fn messages -> [message | messages] end)
      |> assign(:chat_clear, false)}
  end

  @impl true
  def handle_info({:user_timedout, _bad_user}, socket) do
    messages = list_chat_messages(socket.assigns.streamer);
    {:noreply,
      socket
      |> assign(:update_action, "replace")
      |> assign(:chat_messages, messages)
      |> assign(:chat_clear, !Enum.any?(messages))}
  end

  @impl true
  def handle_info({:user_banned, _}, socket) do
    messages = list_chat_messages(socket.assigns.streamer);
    {:noreply,
      socket
      |> assign(:update_action, "replace")
      |> assign(:chat_messages, messages)
      |> assign(:chat_clear, !Enum.any?(messages))}
  end

  @impl true
  def handle_info({:chat_cleared, _}, socket) do
    {:noreply,
      socket
      |> assign(:update_action, "replace")
      |> assign(:chat_messages, list_chat_messages(socket.assigns.streamer))
      |> assign(:chat_clear, true)}
  end

  defp list_chat_messages(streamer) do
    Chat.list_chat_messages(streamer)
  end
end
