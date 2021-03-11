defmodule Glimesh.Repo.Migrations.AddTeamRoles do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :team_role, :string, default: nil
    end
  end
end
