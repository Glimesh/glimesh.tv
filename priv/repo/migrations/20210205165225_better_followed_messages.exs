defmodule Glimesh.Repo.Migrations.BetterFollowedMessages do
  use Ecto.Migration

  def change do
    alter table(:chat_messages) do
      add :is_followed_message, :boolean, default: false
    end
  end
end
