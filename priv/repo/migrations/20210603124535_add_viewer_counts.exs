defmodule Glimesh.Repo.Migrations.AddViewerCounts do
  use Ecto.Migration

  def change do
    alter table(:streams) do
      add :viewer_counts, {:array, :integer}, default: []
    end
  end
end
