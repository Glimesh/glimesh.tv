defmodule GlimeshWeb.Chat.Components.ChatMessage do
  use GlimeshWeb, :component

  alias Glimesh.Accounts.User
  alias Glimesh.Chat.ChatMessage
  alias Glimesh.Chat.ChatMessage.Metadata

  alias GlimeshWeb.Components.UserEffects

  attr :message, ChatMessage, required: true

  attr :permissions, :map,
    default: %{
      can_short_timeout: false,
      can_long_timeout: false,
      can_ban: false,
      can_unban: false,
      can_delete: false
    }

  attr :user, User

  def message(assigns) do
    ~H"""
    <div
      id={"chat-message-#{@message.id}"}
      data-user-id={@message.user.id}
      class={[
        "bg-slate-800 m-2 rounded-lg p-2",
        chat_message_class(@message)
      ]}
    >
      <div class="flex justify-between mb-1">
        <div>
          <%= if Map.get(@permissions, :can_delete, false)  do %>
            <i
              class="delete-message fas fa-trash fa-fw chat-mod-icon"
              phx-click="delete_message"
              phx-value-user={@message.user.username}
              phx-value-message={@message.id}
              data-toggle="tooltip"
              title={gettext("Delete message.")}
            >
            </i>
          <% end %>
          <%= if Map.get(@permissions, :can_short_timeout, false) do %>
            <i
              class="short-timeout fas fa-stopwatch fa-fw chat-mod-icon"
              phx-click="short_timeout_user"
              phx-value-user={@message.user.username}
              data-toggle="tooltip"
              title={gettext("Timeout user for 5 minutes.")}
            >
            </i>
          <% end %>
          <%= if Map.get(@permissions, :can_long_timeout, false)  do %>
            <i
              class="long-timeout fas fa-clock fa-fw chat-mod-icon"
              phx-click="long_timeout_user"
              phx-value-user={@message.user.username}
              data-toggle="tooltip"
              title={gettext("Timeout user for 15 minutes.")}
            >
            </i>
          <% end %>
          <%= if Map.get(@permissions, :can_ban, false)  do %>
            <i
              class="ban fas fa-gavel fa-fw chat-mod-icon"
              phx-click="ban_user"
              phx-value-user={@message.user.username}
              data-confirm={
                gettext("Are you sure you wish to permanently ban %{username}?",
                  username: @message.user.displayname
                )
              }
              data-toggle="tooltip"
              title={gettext("Ban user from channel.")}
            >
            </i>
          <% end %>
        </div>
        <div class="flex-auto">
          <div class="flex space-x-2">
            <UserEffects.avatar user={@message.user} class="w-6 h-6" />
            <UserEffects.displayname user={@message.user} />
            <small id={"small-#{@message.id}"} class="text-gray-400 chat-timestamp">
              @
              <local-time
                id={"timestamp-#{@message.id}"}
                phx-update="ignore"
                datetime={"#{@message.inserted_at}Z"}
                format="micro"
                hour="numeric"
                minute="2-digit"
                second="2-digit"
              >
                <%= NaiveDateTime.to_time(@message.inserted_at) %>
              </local-time>
            </small>
          </div>
        </div>

        <.badge message={@message} />
      </div>
      <div class={["user-message", "d-inline d-md-block"]}>
        <%= if @message.is_followed_message or @message.is_subscription_message,
          do: Glimesh.Chat.Effects.render_username(@message) %>
        <%= raw(Glimesh.Chat.Renderer.render(@message.tokens)) %>
      </div>
    </div>
    """
  end

  def subscriber_badge(assigns) do
    ~H"""
    <span class="badge badge-secondary" data-toggle="tooltip" title={gettext("Channel Subscriber")}>
      <Icons.subscriber />
    </span>
    """
  end

  def moderator_badge(assigns) do
    ~H"""
    <span class="badge badge-primary">Mod</span>
    """
  end

  def streamer_badge(assigns) do
    ~H"""
    <span class="badge badge-primary">Streamer</span>
    """
  end

  attr :message, ChatMessage, required: true

  def badge(assigns) do
    case assigns.message do
      %ChatMessage{metadata: %Metadata{streamer: true}} ->
        streamer_badge(assigns)

      %ChatMessage{metadata: %Metadata{subscriber: true, moderator: true}} ->
        ~H"""
        <.moderator_badge /> <.subscriber_badge />
        """

      %ChatMessage{metadata: %Metadata{moderator: true}} ->
        moderator_badge(assigns)

      %ChatMessage{metadata: %Metadata{subscriber: true}} ->
        subscriber_badge(assigns)

      _ ->
        ~H"""

        """
    end
  end

  defp chat_message_class(%ChatMessage{} = message) do
    cond do
      message.is_subscription_message -> "bg-secondary text-white"
      message.is_followed_message -> "border border-info"
      Glimesh.Chat.Effects.user_in_message(@user, message) -> "bubble mention"
      true -> ""
    end
  end
end
