defmodule GlimeshWeb.Chat.MessageForm do
  use GlimeshWeb, :live_component

  alias Glimesh.Chat
  alias Glimesh.Emotes

  alias GlimeshWeb.Components.Icons

  alias Phoenix.LiveView.JS

  def render(assigns) do
    ~H"""
    <div id="chat-form" phx-hook="Chat" data-emotes={@emotes}>
      <.form
        :let={f}
        for={@changeset}
        id="chat_message-form"
        class="bg-slate-800"
        phx-target={@myself}
        phx-submit="send"
      >
        <%= if message = f.errors[:message] do %>
          <div id="channel-footer" class="channel-footer">
            <span class="text-danger"><%= translate_error(message) %></span>
          </div>
        <% end %>

        <div class="flex text-white">
          <div id="emoji-selector" class="input-group-prepend">
            <button type="button" class="input-group-text emoji-activator p-2">
              <Icons.emotes class="w-6 h-6" />
            </button>
          </div>

          <%= if @disabled do %>
            <div class="input-group-prepend input-group-mock-parent flex-grow-1">
              <span class="input-group-text input-group-mock-input d-inline-block flex-grow-1">
                <%= link("Register", to: ~p"/users/register") %> or <%= link(
                  "Login",
                  to: ~p"/users/log_in"
                ) %> to chat!
              </span>
            </div>
          <% else %>
            <%= text_input(f, :message,
              class: "rounded-none",
              placeholder: gettext("Send a message"),
              autocomplete: "off",
              maxlength: "255",
              disabled: @disabled
            ) %>
          <% end %>

          <div class="relative">
            <button
              type="button"
              class="rounded-lg group-hover:bg-gray-700 group-hover:rounded-b-none p-2"
              phx-click={toggle_dropdown("#chat-dropdown")}
            >
              <Icons.cog class="w-6 h-6" />
            </button>

            <div
              id="chat-dropdown"
              class="hidden absolute right-0 z-10 mt-2 w-48 origin-top-right rounded-md bg-slate-800 py-1 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
            >
              <a
                href="#"
                onclick={
                  "window.open('" <>
                  ~p"/#{@channel_username}/chat" <> "', '_blank',
                                'width=400,height=600,location=no,menubar=no,toolbar=no')"
                }
              >
                <%= gettext("Pop-out Chat") %>
              </a>
              <%= if @user do %>
                <a
                  id="toggle-timestamps"
                  href="#"
                  phx-click="toggle_timestamps"
                  phx-value-user={@user.username}
                >
                  <%= if @show_timestamps,
                    do: gettext("Hide Timestamps"),
                    else: gettext("Show Timestamps") %>
                </a>

                <a
                  id="toggle-mod-icons"
                  href="#"
                  phx-click="toggle_mod_icons"
                  phx-value-user={@user.username}
                >
                  <%= if @show_mod_icons,
                    do: gettext("Hide Mod Icons"),
                    else: gettext("Show Mod Icons") %>
                </a>
              <% else %>
                <a id="toggle-timestamps" href="#" phx-click="toggle_timestamps">
                  <%= if @show_timestamps,
                    do: gettext("Hide Timestamps"),
                    else: gettext("Show Timestamps") %>
                </a>
              <% end %>
            </div>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(
        %{chat_message: chat_message, user: user, streamer: streamer, channel: channel} = assigns,
        socket
      ) do
    changeset = Chat.change_chat_message(chat_message)

    include_animated = if user, do: Glimesh.Payments.is_platform_subscriber?(user), else: false
    global_emotes = if user, do: Emotes.list_emotes(include_animated, user.id), else: []
    channel_emotes = if user, do: Emotes.list_emotes_for_channel(channel, user.id), else: []
    emotes = Emotes.convert_for_json(channel_emotes ++ global_emotes)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)
     |> assign(:emotes, emotes)
     |> assign(:channel_username, streamer.username)
     |> assign(:disabled, is_nil(user))}
  end

  @impl true
  def handle_event("send", %{"chat_message" => chat_message_params}, socket) do
    # Pull a fresh user and channel from the database in case something has changed
    user = Glimesh.Accounts.get_user!(socket.assigns.user.id)
    channel = Glimesh.ChannelLookups.get_channel!(socket.assigns.channel.id)
    save_chat_message(socket, channel, user, chat_message_params)
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

  defp toggle_dropdown(js \\ %JS{}, to) do
    js
    |> JS.toggle(
      in: {
        "transition ease-out duration-100",
        "transform opacity-0 scale-95",
        "transform opacity-100 scale-100"
      },
      out: {
        "transition ease-in duration-75",
        "transform opacity-100 scale-100",
        "transform opacity-0 scale-95"
      },
      to: to
    )
  end
end
