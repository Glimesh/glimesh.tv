defmodule GlimeshWeb.ChatLive.Index do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Chat
  alias Glimesh.Chat.ChatMessage
  alias Glimesh.Presence
  alias Glimesh.Streams

  @impl true
  def mount(_params, %{"channel_id" => channel_id} = session, socket) do
    if connected?(socket), do: Streams.subscribe_to(:chat, channel_id)

    channel = Streams.get_channel!(channel_id)

    if session["user"] do
      user = session["user"]

      Presence.track_presence(
        self(),
        Streams.get_subscribe_topic(:chatters, channel.id),
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
      |> assign(:channel_chat_parser_config, Glimesh.Chat.get_chat_parser_config(channel))
      |> assign(:update_action, "replace")
      |> assign(:channel, channel)
      |> assign(:user, session["user"])
      |> assign(:is_moderator, Glimesh.Chat.is_moderator?(channel, session["user"]))
      |> assign(:chat_messages, list_chat_messages(channel))
      |> assign(:chat_message, %ChatMessage{})

    {:ok, new_socket, temporary_assigns: [chat_messages: []]}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    chat_message = Chat.get_chat_message!(id)
    {:ok, _} = Chat.delete_chat_message(chat_message)

    {:noreply, assign(socket, :chat_messages, list_chat_messages(socket.assigns.channel))}
  end

  @impl true
  def handle_event("timeout_user", %{"user" => to_ban_user}, socket) do
    Streams.timeout_user(
      socket.assigns.channel,
      socket.assigns.user,
      Accounts.get_by_username!(to_ban_user)
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("ban_user", %{"user" => to_ban_user}, socket) do
    Streams.timeout_user(
      socket.assigns.channel,
      socket.assigns.user,
      Accounts.get_by_username!(to_ban_user)
    )

    {:noreply, assign(socket, :chat_messages, list_chat_messages(socket.assigns.channel))}
  end

  @impl true
  def handle_info({:chat_message, message}, socket) do
    {:noreply,
     socket
     |> assign(:update_action, "append")
     |> push_event("scroll_chat", %{})
     |> update(:chat_messages, fn messages -> [message | messages] end)}
  end

  @impl true
  def handle_info({:user_timedout, _bad_user}, socket) do
    # Gotta figure out why messages here is [], I guess it's the temporary assigns above? But why does :chat_sent work?
    # {:noreply, socket |> assign(:update_action, "replace") |> update(:chat_messages, fn messages -> Enum.reject(messages, fn x -> x.user_id === bad_user.id end) |> IO.inspect() end)}
    {:noreply,
     socket
     |> assign(:update_action, "replace")
     |> assign(:chat_messages, list_chat_messages(socket.assigns.channel))}
  end

  defp list_chat_messages(channel) do
    Chat.list_chat_messages(channel)
  end
end
