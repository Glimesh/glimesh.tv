defmodule Glimesh.Repo.Migrations.AddReactionGifsToChannel do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :allow_reaction_gifs, :boolean, default: false
    end
  end
end
