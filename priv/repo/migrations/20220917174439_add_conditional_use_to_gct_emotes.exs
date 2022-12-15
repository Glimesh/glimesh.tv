defmodule Glimesh.Repo.Migrations.AddConditionalUseTo_GCTEmotes do
  use Ecto.Migration

  def change do
    alter table(:emotes) do
      add :approved_for_global_use, :boolean, default: true
    end
  end
end
