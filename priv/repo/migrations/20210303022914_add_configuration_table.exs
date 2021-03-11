defmodule Glimesh.Repo.Migrations.AddConfigurationTable do
  use Ecto.Migration

  def change do
    create table(:configurations) do
      add :key, :string
      add :value, :text

      timestamps()
    end

    create unique_index(:configurations, [:key])
  end
end
