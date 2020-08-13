defmodule GlimeshWeb.ChatLive.Index do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Chat
  alias Glimesh.Chat.ChatMessage
  alias Glimesh.Presence
  alias Glimesh.Streams

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket), do: Chat.subscribe()

    streamer = session["streamer"]

    if session["user"] do
      user = session["user"]

      Presence.track_presence(self(), "chatters:#{streamer.username}", user.id, %{
        typing: false,
        username: user.username,
        avatar: Glimesh.Avatar.url({user.avatar, user}, :original),
        user_id: user.id,
        size: 48
      })
    end

    new_socket =
      socket
      |> assign(:update_action, "replace")
      |> assign(:streamer, streamer)
      |> assign(:user, session["user"])
      |> assign(:can_moderate, Glimesh.Chat.can_moderate?(streamer, session["user"]))
      |> assign(:chat_messages, list_chat_messages(streamer))
      |> assign(:chat_message, %ChatMessage{})

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
    Streams.timeout_user(
      socket.assigns.streamer,
      socket.assigns.user,
      Accounts.get_by_username!(to_ban_user)
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("ban_user", %{"user" => to_ban_user}, socket) do
    Streams.timeout_user(
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
     |> update(:chat_messages, fn messages -> [message | messages] end)}
  end

  @impl true
  def handle_info({:user_timedout, _bad_user}, socket) do
    # Gotta figure out why messages here is [], I guess it's the temporary assigns above? But why does :chat_sent work?
    # {:noreply, socket |> assign(:update_action, "replace") |> update(:chat_messages, fn messages -> Enum.reject(messages, fn x -> x.user_id === bad_user.id end) |> IO.inspect() end)}
    {:noreply,
     socket
     |> assign(:update_action, "replace")
     |> assign(:chat_messages, list_chat_messages(socket.assigns.streamer))}
  end

  defp list_chat_messages(streamer) do
    Chat.list_chat_messages(streamer)
  end
end
