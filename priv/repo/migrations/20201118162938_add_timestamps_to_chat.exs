defmodule Glimesh.Repo.Migrations.AddTimestampsToChat do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :show_timestamps?, :boolean, default: false
    end
  end
end
