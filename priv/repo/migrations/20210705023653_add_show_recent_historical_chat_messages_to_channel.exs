defmodule Glimesh.Repo.Migrations.AddShowRecentHistoricalChatMessagesToChannel do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :show_recent_chat_messages_only, :boolean, default: false
    end
  end
end
