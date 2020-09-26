defmodule GlimeshWeb.ChatLive.MessageForm do
  use GlimeshWeb, :live_component

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
    save_chat_message(socket, socket.assigns.channel, socket.assigns.user, chat_message_params)
  end

  defp save_chat_message(socket, channel, user, chat_message_params) do
    case Chat.create_chat_message(channel, user, chat_message_params) do
      {:ok, _chat_message} ->
        {:noreply,
         socket
         |> put_flash(:info, "Chat message created successfully")
         |> assign(:changeset, Chat.empty_chat_message())}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
