defmodule Glimesh.Repo.Migrations.AddSvgFlagToEmotes do
  use Ecto.Migration

  def change do
    alter table(:emotes) do
      add :svg, :boolean, default: true
    end
  end
end
