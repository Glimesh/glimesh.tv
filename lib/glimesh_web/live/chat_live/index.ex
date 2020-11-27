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
      |> assign(:channel_chat_parser_config, Chat.get_chat_parser_config(channel))
      |> assign(:update_action, "replace")
      |> assign(:channel, channel)
      |> assign(:user, session["user"])
      |> assign(:permissions, Chat.get_moderator_permissions(channel, session["user"]))
      |> assign(:chat_messages, list_chat_messages(channel))
      |> assign(:chat_message, %ChatMessage{})
      |> assign(:show_timestamps, (if session["user"], do: session["user"].show_timestamps, else: false))

    {:ok, new_socket}
  end

  @impl true
  def handle_event("short_timeout_user", %{"user" => to_ban_user}, socket) do
    Chat.short_timeout_user(
      socket.assigns.user,
      socket.assigns.channel,
      Accounts.get_by_username!(to_ban_user)
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("long_timeout_user", %{"user" => to_ban_user}, socket) do
    Chat.long_timeout_user(
      socket.assigns.user,
      socket.assigns.channel,
      Accounts.get_by_username!(to_ban_user)
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("ban_user", %{"user" => to_ban_user}, socket) do
    Chat.ban_user(
      socket.assigns.user,
      socket.assigns.channel,
      Accounts.get_by_username!(to_ban_user)
    )

    {:noreply, assign(socket, :chat_messages, list_chat_messages(socket.assigns.channel))}
  end

  @impl true
  def handle_info({:chat_message, message}, socket) do
    {:noreply,
     socket
     |> assign(:update_action, "append")
     |> push_event("new_chat_message", %{})
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

  defp list_chat_messages(channel, limit) do
    # Only currently used when updating elements about the chat.
    # Just makes sure that if the limit is above 50, it's set back to 50.
    # Otherwise you could possibly load a few hundred messages when updating elements.
    # The last 50 should do fine without anyone noticing.
    # If the viewer's chat currently has less than 50 messages then it just gets however many there are.
    limit = if limit > 50, do: 50, else: limit
    Chat.list_chat_messages(channel, limit)
  end

  defp background_style(channel) do
    url = Glimesh.ChatBackground.url({channel.chat_bg, channel}, :original)

    "--chat-bg-image: url('#{url}');"
  end

  @impl true
  def handle_event("toggle_timestamps", _params, socket) do
    timestamp_state = Kernel.not(socket.assigns.show_timestamps)
    {:ok, user} =
      Glimesh.Accounts.User.user_settings_changeset(socket.assigns.user, %{show_timestamps: timestamp_state})
      |> Glimesh.Repo.update()
    {:noreply,
     socket
     |> assign(:update_action, "replace")
     |> assign(:chat_messages, list_chat_messages(socket.assigns.channel, Kernel.length(socket.assigns.chat_messages)))
     |> assign(:show_timestamps, timestamp_state)
     |> assign(:user, user)}
  end
end
