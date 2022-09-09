defmodule Glimesh.Repo.Migrations.AddInteractive do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :interactive_project, :string
      add :interactive_enabled, :boolean, default: false
    end
  end
end
