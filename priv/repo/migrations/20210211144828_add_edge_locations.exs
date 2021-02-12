defmodule Glimesh.Repo.Migrations.AddEdgeLocations do
  use Ecto.Migration

  def change do
    create table(:janus_edge_routes) do
      add :hostname, :string
      add :url, :string
      add :priority, :float, default: 1.00
      add :available, :boolean
      add :country_codes, {:array, :string}

      timestamps()
    end
  end
end
