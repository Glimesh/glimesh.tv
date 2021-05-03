defmodule Glimesh.Repo.Migrations.CreateAppBorutaLink do
  use Ecto.Migration

  def change do
    alter table(:apps) do
      add :client_id, references(:clients, on_delete: :nothing, type: :uuid)
    end
  end
end
