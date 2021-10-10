defmodule Glimesh.Repo.Migrations.CreatingEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :type, :string
      add :start_date, :naive_datetime
      add :end_date, :naive_datetime
      add :label, :string
      add :description, :text
      add :featured, :boolean
      add :channel, :string
      add :image, :string

      timestamps()
    end

    alter table(:users) do
      add :is_events_team, :boolean, default: false
    end
  end
end
