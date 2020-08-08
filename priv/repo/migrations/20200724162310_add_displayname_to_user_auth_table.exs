defmodule Glimesh.Repo.Migrations.AddDisplaynameToUserAuthTable do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :displayname, :string, default: nil
      modify :username, :citext
    end

    execute "UPDATE users SET displayname = username"
  end

  def down do
    execute "UPDATE users SET username = displayname"
    execute "UPDATE users SET displayname = NULL"

    alter table(:users) do
      remove :displayname
      modify :username, :string
    end
  end
end
