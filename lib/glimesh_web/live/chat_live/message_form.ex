defmodule GlimeshWeb.ChatLive.MessageForm do
  use GlimeshWeb, :live_component

  alias Glimesh.ChannelLookups
  alias Glimesh.Chat
  alias Glimesh.Emotes

  @impl true
  def update(%{chat_message: chat_message, user: user, channel: channel} = assigns, socket) do
    changeset = Chat.change_chat_message(chat_message)

    include_animated = if user, do: Glimesh.Payments.is_platform_subscriber?(user), else: false
    global_emotes = if user, do: Emotes.list_emotes(include_animated, user.id), else: []
    channel_emotes = if user, do: Emotes.list_emotes_for_channel(channel, user.id), else: []
    emotes = Emotes.convert_for_json(channel_emotes ++ global_emotes)

    reaction_gifs_allowed =
      if not is_nil(user) and channel.user_id == user.id do
        Glimesh.Streams.Channel.allow_reaction_gifs_site_wide?()
      else
        Glimesh.Streams.Channel.allow_reaction_gifs?(channel)
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:emotes, emotes)
     |> assign(:channel_username, channel.user.username)
     |> assign(:disabled, is_nil(user))
     |> assign(:allow_reaction_gifs, reaction_gifs_allowed)}
  end

  @impl true
  def handle_event("send", %{"chat_message" => chat_message_params}, socket) do
    # Pull a fresh user and channel from the database in case something has changed
    user = Glimesh.Accounts.get_user!(socket.assigns.user.id)
    channel = ChannelLookups.get_channel!(socket.assigns.channel.id)
    save_chat_message(socket, channel, user, chat_message_params)
  end

  def handle_event("tenorsettings", _params, socket) do
    settings = Enum.into(Application.fetch_env!(:glimesh, :tenor_config), %{})
    {:reply, settings, socket}
  end

  def handle_event("sendtenormessage", %{"chat_params" => chat_message_params}, socket) do
    # Pull a fresh user and channel from the database in case something has changed
    user = Glimesh.Accounts.get_user!(socket.assigns.user.id)
    channel = ChannelLookups.get_channel!(socket.assigns.channel.id)
    save_tenor_chat_message(socket, channel, user, chat_message_params)
  end

  def handle_event("user_autocomplete", %{"partial_usernames" => partial_usernames}, socket) do
    channel = ChannelLookups.get_channel!(socket.assigns.channel.id)
    user_suggestions = Chat.get_recent_chatters_username_autocomplete(channel, partial_usernames)

    {:reply, %{suggestions: user_suggestions}, socket}
  end

  defp save_chat_message(socket, channel, user, chat_message_params) do
    case Chat.create_chat_message(user, channel, chat_message_params) do
      {:ok, _chat_message} ->
        {:noreply,
         socket
         |> assign(:changeset, Chat.empty_chat_message())}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}

      # Permissions errors
      {:error, error_message} ->
        error_changeset = %Ecto.Changeset{
          action: :validate,
          changes: chat_message_params,
          errors: [
            message: {error_message, [validation: :required]}
          ],
          data: %Glimesh.Chat.ChatMessage{},
          valid?: false
        }

        {:noreply, assign(socket, changeset: error_changeset)}
    end
  end

  defp save_tenor_chat_message(socket, channel, user, chat_message_params) do
    case Chat.create_tenor_message(user, channel, chat_message_params) do
      {:ok, _chat_message} ->
        {:noreply,
         socket
         |> assign(:changeset, Chat.empty_chat_message())
         |> push_event("scroll_to_bottom", %{})}

      {:error, %Ecto.Changeset{} = _changeset} ->
        {:noreply,
         put_flash(socket, :error, gettext("Unable to send reaction gif chat message."))}

      # Permissions errors
      {:error, error_message} ->
        {:noreply, put_flash(socket, :error, error_message)}
    end
  end
end
