defmodule Glimesh.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat_messages) do
      add :streamer_id, references(:users, on_delete: :delete_all), null: false
      add :message, :string
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

  end
end
