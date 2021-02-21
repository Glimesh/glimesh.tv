defmodule Glimesh.Repo.Migrations.AddChatTokens do
  use Ecto.Migration

  import Ecto.Query

  def change do
    alter table(:chat_messages) do
      add :tokens, {:array, :map}, default: []
    end

    flush()

    channels = Glimesh.ChannelLookups.list_channels()

    Enum.each(channels, fn channel ->
      chat_messages =
        Glimesh.Repo.all(
          from(m in Glimesh.Chat.ChatMessage,
            where: m.channel_id == ^channel.id,
            order_by: [desc: :inserted_at]
          )
        )

      Enum.each(chat_messages, fn msg ->
        tokens =
          Glimesh.Chat.Parser.parse(msg.message, Glimesh.Chat.get_chat_parser_config(channel))

        changeset =
          msg
          |> Ecto.Changeset.change()
          |> Glimesh.Chat.ChatMessage.token_changeset(tokens)

        Glimesh.Repo.update!(changeset)
      end)
    end)
  end
end
