defmodule Glimesh.Repo.Migrations.AddNewStreamerFlagToChannels do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :is_new_streamer, :boolean, default: false
    end
  end
end
