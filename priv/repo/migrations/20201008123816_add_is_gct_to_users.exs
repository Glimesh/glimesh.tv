defmodule Glimesh.Repo.Migrations.AddIsGctToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_gct, :boolean, default: false
      add :gct_level, :integer
    end
  end
end
