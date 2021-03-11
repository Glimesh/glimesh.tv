defmodule Glimesh.Resolvers.ChatResolver do
  @moduledoc false

  use Appsignal.Instrumentation.Decorators

  alias Glimesh.Accounts
  alias Glimesh.Chat

  @decorate transaction_event()
  def create_chat_message(
        _parent,
        %{channel_id: channel_id, message: message_obj},
        %{context: %{user_access: ua}}
      ) do
    with :ok <- Bodyguard.permit(Glimesh.Resolvers.Scopes, :chat, ua) do
      channel = Glimesh.ChannelLookups.get_channel!(channel_id)
      # Force a refresh of the user just in case they are platform banned
      user = Accounts.get_user!(ua.user.id)

      Chat.create_chat_message(user, channel, message_obj)
    end
  end

  @decorate transaction_event()
  def short_timeout_user(parent, params, context) do
    perform_channel_action(parent, params, context, :short_timeout)
  end

  @decorate transaction_event()
  def long_timeout_user(parent, params, context) do
    perform_channel_action(parent, params, context, :long_timeout)
  end

  @decorate transaction_event()
  def ban_user(parent, params, context) do
    perform_channel_action(parent, params, context, :ban)
  end

  @decorate transaction_event()
  def unban_user(parent, params, context) do
    perform_channel_action(parent, params, context, :unban)
  end

  @doc """
  Send an action to the Chat context to figure out permissions on, but first make sure the user_access is allowed access to the chat.
  """
  def perform_channel_action(
        _parent,
        %{channel_id: channel_id, user_id: user_id},
        %{context: %{user_access: ua}},
        action
      ) do
    with :ok <- Bodyguard.permit(Glimesh.Resolvers.Scopes, :chat, ua) do
      channel = Glimesh.ChannelLookups.get_channel!(channel_id)
      moderator = Accounts.get_user!(ua.user.id)
      user = Accounts.get_user!(user_id)

      case action do
        :short_timeout -> Chat.short_timeout_user(moderator, channel, user)
        :long_timeout -> Chat.long_timeout_user(moderator, channel, user)
        :ban -> Chat.ban_user(moderator, channel, user)
        :unban -> Chat.unban_user(moderator, channel, user)
      end
    end
  end
end
