defmodule Glimesh.Repo.Migrations.AddingPronouns do
  use Ecto.Migration

  def change do
      alter table(:users) do
      add :pronoun_id, :string
    end
  end
end
