defmodule Glimesh.Repo.Migrations.AddIsGctToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_community_champion, :boolean, default: false
    end
  end
end
