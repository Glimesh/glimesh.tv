defmodule GlimeshWeb.ChatLive.MessageForm do
  use GlimeshWeb, :live_component

  alias Glimesh.Accounts
  alias Glimesh.Chat
  alias Glimesh.Presence
  alias Glimesh.Streams

  @impl true
  def update(%{chat_message: chat_message, user: user} = assigns, socket) do
    changeset = Chat.change_chat_message(chat_message)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:disabled, is_nil(user))}
  end

  @impl true
  def handle_event("validate", %{"chat_message" => chat_message_params}, socket) do
    changeset =
      socket.assigns.chat_message
      |> Chat.change_chat_message(chat_message_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("send", %{"chat_message" => chat_message_params}, socket) do
    {is_command, command} = chat_message_is_command(chat_message_params)

    if is_command do
      case command do
        {:timeout, components} ->
          timeout_user(
            socket.assigns.streamer,
            socket.assigns.user,
            components
          )

        {:ban, components} ->
          [user] = components

          Chat.ban_user(
            socket.assigns.streamer,
            socket.assigns.user,
            Accounts.get_by_username!(String.replace(user, "@", ""))
          )

        {:unban, components} ->
          [user] = components

          Chat.unban_user(
            socket.assigns.streamer,
            socket.assigns.user,
            Accounts.get_by_username!(String.replace(user, "@", ""))
          )

        {:clear, _} ->
          Chat.clear_chat(socket.assigns.streamer, socket.assigns.user)

        _ ->
          command
          # |> IO.inspect()
      end

      {:noreply,
       socket
       |> put_flash(:info, "Command recived")
       |> assign(:changeset, Chat.empty_chat_message())}
    else
      save_chat_message(socket, socket.assigns.channel, socket.assigns.user, chat_message_params)
    end
  end

  defp timeout_user(channel, moderator, components) do
    [user, time] = components
    date_time = DateTime.utc_now()

    if String.contains?(time, "s") and !String.contains?(time, ["h", "m"]) do
      timeout_user(
        channel,
        moderator,
        Accounts.get_by_username!(String.replace(user, "@", "")),
        date_time,
        time,
        1,
        "s"
      )
    end

    if String.contains?(time, "m") and !String.contains?(time, ["h", "s"]) do
      timeout_user(
        channel,
        moderator,
        Accounts.get_by_username!(String.replace(user, "@", "")),
        date_time,
        time,
        60,
        "m"
      )
    end

    if String.contains?(time, "h") and !String.contains?(time, ["s", "m"]) do
      timeout_user(
        channel,
        moderator,
        Accounts.get_by_username!(String.replace(user, "@", "")),
        date_time,
        time,
        60 * 60,
        "h"
      )
    end
  end

  defp timeout_user(channel, moderator, user, date_time, time, time_multiplier, time_modifier) do
    time =
      time
      |> String.trim()
      |> String.replace(time_modifier, "")

    if Integer.parse(time) === :error do
      raise "Time was not a parsable integer"
    else
      {time_int, _} = Integer.parse(time)
      date_time = DateTime.add(date_time, time_int * time_multiplier)

      Chat.timeout_user(
        channel,
        moderator,
        user,
        date_time
      )
    end
  end

  defp save_chat_message(socket, channel, user, chat_message_params) do
    case Chat.create_chat_message(channel, user, chat_message_params) do
      {:ok, _chat_message} ->
        Presence.update_presence(
          self(),
          Streams.get_subscribe_topic(:chatters, channel.id),
          user.id,
          fn x ->
            %{x | size: x.size + 2}
          end
        )

        {:noreply,
         socket
         |> put_flash(:info, "Chat message created successfully")
         |> assign(:changeset, Chat.empty_chat_message())}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp chat_message_is_command(%{"message" => message}) do
    {first, rest} = String.split_at(message, 1)

    if first == "/" do
      [command | components] = String.split(rest)
      ## this is annoying but hey you do what you do to get it to work
      case command do
        "timeout" ->
          {true, {:timeout, components}}

        "ban" ->
          {true, {:ban, components}}

        "unban" ->
          {true, {:unban, components}}

        "clear" ->
          {true, {:clear, components}}

        _ ->
          {false, nil}
      end
    else
      {false, nil}
    end
  end
end
