defmodule Glimesh.Repo.Migrations.AddRaidingFeature do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :allow_raiding, :boolean, default: false
      add :only_followed_can_raid, :boolean, default: false
      add :raid_message, :string, default: "{streamer} is raiding you with {count} viewers!"
    end

    alter table(:chat_messages) do
      add :is_raid_message, :boolean, default: false
    end

    alter table(:streams) do
      add :count_raids, :integer
      add :count_raid_viewers, :integer
    end

    create table(:channel_banned_raids) do
      add :channel_id, references(:channels), null: false
      add :banned_channel_id, references(:channels), null: false

      timestamps()
    end

    create_raid_status_enum_query =
      "CREATE TYPE raid_status AS ENUM ('pending', 'complete', 'cancelled')"

    drop_raid_status_enum_query = "DROP TYPE raid_status"
    execute(create_raid_status_enum_query, drop_raid_status_enum_query)

    create table(:channel_raids) do
      add :group_id, :uuid, null: false
      add :status, :raid_status
      add :started_by_id, references(:users), null: false
      add :target_channel_id, references(:channels), null: false

      timestamps()
    end

    create unique_index(:channel_raids, [:group_id])

    create table(:raid_users) do
      add :group_id, references(:channel_raids, column: :group_id, type: :uuid), null: false
      add :user_id, references(:users), null: false
      add :status, :raid_status

      timestamps()
    end

    create unique_index(:raid_users, [:group_id, :user_id])
  end
end
