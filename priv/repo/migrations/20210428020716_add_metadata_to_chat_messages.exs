defmodule Glimesh.Repo.Migrations.AddMetadataToChatMessages do
  use Ecto.Migration

  def change do
    alter table(:chat_messages) do
      add :metadata, :map
    end
  end
end
