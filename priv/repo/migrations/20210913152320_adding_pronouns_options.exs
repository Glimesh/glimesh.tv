defmodule Glimesh.Repo.Migrations.AddingPronounsOptions do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :pronoun, :string
      add :show_pronoun_stream, :boolean
      add :show_pronoun_profile, :boolean
    end
  end
end
