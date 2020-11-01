defmodule Glimesh.Repo.Migrations.AddChannelBans do
  use Ecto.Migration

  def change do
    create table(:channel_bans) do
      add :channel_id, references(:channels), null: false
      add :user_id, references(:users), null: false

      add :expires_at, :naive_datetime
      add :reason, :string

      timestamps()
    end
  end
end
