defmodule Glimesh.Resolvers.ChatResolver do
  @moduledoc false

  def create_chat_message(
        _parent,
        %{channel_id: channel_id, message: message_obj},
        %{context: %{user_access: ua}}
      ) do
    with :ok <- Bodyguard.permit(Glimesh.Resolvers.Scopes, :chat, ua) do
      channel = Glimesh.Streams.get_channel!(channel_id)

      Glimesh.Chat.create_chat_message(ua.user, channel, message_obj)
    end
  end
end
