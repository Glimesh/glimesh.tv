defmodule Glimesh.Repo.Migrations.AddHostingFeature do
  use Ecto.Migration

  def change do
    alter table("channels") do
      add :allow_hosting, :boolean, default: false
    end

    create table(:channel_hosts) do
      add :hosting_channel_id, references(:channels, column: :id), null: false
      add :target_channel_id, references(:channels, column: :id), null: false
      add :status, :string, null: false, default: "ready"
      add :last_hosted_date, :naive_datetime, null: true

      timestamps()
    end

    create unique_index(:channel_hosts, [:hosting_channel_id, :target_channel_id])
  end
end
