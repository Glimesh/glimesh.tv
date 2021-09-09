defmodule Glimesh.Repo.Migrations.PronounStream do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :pronoun_stream, :boolean
      add :pronoun_profile, :boolean
    end
  end
end
