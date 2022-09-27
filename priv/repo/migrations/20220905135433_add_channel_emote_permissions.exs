defmodule Glimesh.Repo.Migrations.AddChannelEmotePermissions do
  use Ecto.Migration

  def change do
    alter table(:emotes) do
      add :require_channel_sub, :boolean, default: false
      add :allow_global_usage, :boolean, default: false
    end
  end
end
