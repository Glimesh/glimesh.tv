defmodule Glimesh.Repo.Migrations.AddDisplaynameToUserAuthTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :displayname, :string, default: nil
    end
  end
end
