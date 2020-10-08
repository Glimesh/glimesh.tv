defmodule Glimesh.Repo.Migrations.AddIsGctToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :is_gct, :boolean, default: false
    end
  end
end
