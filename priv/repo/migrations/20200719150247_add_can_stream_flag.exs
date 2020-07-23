defmodule Glimesh.Repo.Migrations.AddCanStreamFlag do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :can_stream, :boolean, default: false
    end
  end
end
