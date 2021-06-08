defmodule Glimesh.Repo.Migrations.AddingHostingToChannels do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :is_hosting, :boolean, default: false
      add :hosted_channel_id, references(:channels)
    end

  end
end
