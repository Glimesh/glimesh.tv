defmodule Glimesh.Repo.Migrations.CreateFollowers do
  use Ecto.Migration

  def change do
    create table(:followers) do
      add :streamer_id, references(:users, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :has_live_notifications, :boolean, default: false, null: false

      timestamps()
    end

    create unique_index(:followers, [:streamer_id, :user_id])
  end
end
