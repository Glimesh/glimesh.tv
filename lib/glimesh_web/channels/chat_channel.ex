defmodule GlimeshWeb.ChatChannel do
  use Phoenix.Channel

  alias Glimesh.Accounts
  alias Glimesh.Chat
  alias Glimesh.Chat.ChatMessage

  @impl true
  def join("chat:" <> user_id, _params, socket) do
    Phoenix.PubSub.subscribe(Glimesh.PubSub, "chats:#{user_id}")
    {:ok, %{method: "welcome", type: "method", data: %{hello: "auth"}}, socket}
  end

  @impl true
  def handle_in("timeout_user", %{"user" => user}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info({:chat_sent, message}, socket) do
    push(socket, "chat_message", %{
      message: message.message,
      user: %{
        id: message.user.id,
        name: message.user.username,
        displayName: message.user.displayname
      }
    })
    {:noreply, socket}
  end

  @impl true
  def handle_info({:user_timedout, bad_user}, socket) do
    push(socket, "user_timeout", %{})
    {:noreply, socket}
  end
end
