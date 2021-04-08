defmodule Glimesh.Repo.Migrations.AddHomepageChannels do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :show_on_homepage, :boolean, default: false
    end

    create table(:homepage_channels) do
      add :channel_id, references(:channels)

      add :slot_started_at, :naive_datetime
      add :slot_ended_at, :naive_datetime

      timestamps()
    end
  end
end
