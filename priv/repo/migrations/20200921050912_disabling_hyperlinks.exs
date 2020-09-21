defmodule Glimesh.Repo.Migrations.DisablingHyperlinks do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :disable_hyperlinks, :boolean, default: false
    end

  end
end
