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

    # Sets a default user_preferences map for the chat if the user is logged out
    user_preferences =
      if session["user"] do
        Accounts.get_user_preference!(session["user"])
      else
        %{
          show_timestamps: false
        }
      end

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
      |> assign(:show_timestamps, user_preferences.show_timestamps)
      |> push_event("update_previous_messages_with_timestamp_state", %{
        show_timestamps: user_preferences.show_timestamps
      })
      |> assign(:user_preferences, user_preferences)

    {:ok, new_socket, temporary_assigns: [chat_messages: []]}
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
  def handle_event("toggle_timestamps", params, socket) when map_size(params) == 0 do
    timestamp_state = Kernel.not(socket.assigns.show_timestamps)
    {:noreply,
     socket
     |> assign(:update_action, "append")
     |> assign(:show_timestamps, timestamp_state)
     |> assign(:user_preferences, %{show_timestamps: timestamp_state})
     |> push_event("update_previous_messages_with_timestamp_state", %{
       show_timestamps: timestamp_state
     })}
  end

  @impl true
  def handle_event("toggle_timestamps", %{"user" => username}, socket) do
    timestamp_state = Kernel.not(socket.assigns.show_timestamps)

    {:ok, user_preferences} =
      Accounts.update_user_preference(socket.assigns.user_preferences, %{
        show_timestamps: timestamp_state
      })

    {:noreply,
     socket
     # Needed so the chat doesn't empty and reload the DOM
     |> assign(:update_action, "append")
     |> assign(:show_timestamps, timestamp_state)
     |> assign(:user_preferences, user_preferences)
     |> push_event("update_previous_messages_with_timestamp_state", %{
       show_timestamps: timestamp_state
     })}
  end

  @impl true
  def handle_info({:chat_message, message}, socket) do
    {:noreply,
     socket
     |> assign(:update_action, "append")
     |> push_event("new_chat_message", %{
       show_timestamps: socket.assigns.user_preferences.show_timestamps,
       message_id: message.id
     })
     |> update(:chat_messages, fn messages -> [message | messages] end)}
  end

  @impl true
  def handle_info({:user_timedout, _bad_user}, socket) do
    # Gotta figure out why messages here is [], I guess it's the temporary assigns above? But why does :chat_sent work?
    # {:noreply, socket |> assign(:update_action, "replace") |> update(:chat_messages, fn messages -> Enum.reject(messages, fn x -> x.user_id === bad_user.id end) |> IO.inspect() end)}

    # Must tell the JS function to re-assign the timestamps since a timeout seems to re-render the entire DOM.
    show_timestamps =
      if socket.assigns.user,
        do: Accounts.get_user_preference!(socket.assigns.user).show_timestamps,
        else: false

    {:noreply,
     socket
     |> assign(:update_action, "replace")
     |> assign(:chat_messages, list_chat_messages(socket.assigns.channel))
     |> push_event("update_previous_messages_with_timestamp_state", %{show_timestamps: show_timestamps})}
  end

  defp list_chat_messages(channel) do
    Chat.list_chat_messages(channel)
  end

  defp background_style(channel) do
    url = Glimesh.ChatBackground.url({channel.chat_bg, channel}, :original)

    "--chat-bg-image: url('#{url}');"
  end
end
