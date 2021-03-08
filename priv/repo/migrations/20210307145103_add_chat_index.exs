defmodule Glimesh.Repo.Migrations.AddChatIndex do
  use Ecto.Migration

  def change do
    create_if_not_exists index(:chat_messages, [:channel_id, :is_visible])
  end
end
