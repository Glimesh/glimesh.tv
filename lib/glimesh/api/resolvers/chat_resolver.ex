defmodule Glimesh.Api.ChatResolver do
  @moduledoc false

  use Appsignal.Instrumentation.Decorators

  alias Glimesh.Accounts
  alias Glimesh.ChannelLookups
  alias Glimesh.Chat

  @decorate transaction_event()
  def create_chat_message(
        _parent,
        %{channel_id: channel_id, message: message_obj},
        %{context: %{user_access: ua}}
      ) do
    with :ok <- Bodyguard.permit(Glimesh.Api.Scopes, :chat, ua) do
      channel = Glimesh.ChannelLookups.get_channel!(channel_id)
      # Force a refresh of the user just in case they are platform banned
      user = Accounts.get_user!(ua.user.id)

      case Chat.create_chat_message(user, channel, message_obj) do
        {:ok, message} ->
          {:ok, message}

        {:error, %Ecto.Changeset{} = changeset} ->
          {:error, Glimesh.Api.parse_ecto_changeset_errors(changeset)}
      end
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
  Sends a delete chat message call, but make sure user_access is allowed
  """
  @decorate transaction_event()
  def delete_chat_message(_parent, %{channel_id: channel_id, message_id: message_id}, %{
        context: %{user_access: ua}
      }) do
    # Send an action to the Chat context to figure out permissions on, but first make sure
    # the user_access is allowed access to the chat.
    with :ok <- Bodyguard.permit(Glimesh.Api.Scopes, :chat, ua) do
      channel = ChannelLookups.get_channel!(channel_id)
      moderator = Accounts.get_user!(ua.user.id)
      chat_message = Chat.get_chat_message!(message_id)
      user = Accounts.get_user!(chat_message.user_id)

      Chat.delete_message(moderator, channel, user, chat_message)
    end
  end

  defp perform_channel_action(
         _parent,
         %{channel_id: channel_id, user_id: user_id},
         %{context: %{user_access: ua}},
         action
       ) do
    with :ok <- Bodyguard.permit(Glimesh.Api.Scopes, :chat, ua) do
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
