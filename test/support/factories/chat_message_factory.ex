defmodule Glimesh.ChatMessageFactory do
  @moduledoc """
  Chat Message Factory
  """

  use ExMachina.Ecto, repo: Glimesh.Repo

  defmacro __using__(_) do
    quote do
      def chat_message_factory do
        %Glimesh.Chat.ChatMessage{
          message: Faker.Lorem.paragraph(1),
          user: build(:user),
          channel: build(:channel),
          metadata: Glimesh.Chat.ChatMessage.Metadata.defaults()
        }
      end
    end
  end
end
