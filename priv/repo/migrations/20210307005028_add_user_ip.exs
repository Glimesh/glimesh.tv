defmodule Glimesh.Repo.Migrations.AddUserIp do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :user_ip, :text
    end
  end
end
