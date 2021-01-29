defmodule Glimesh.Repo.Migrations.CreateChannelTags do
  use Ecto.Migration

  def change do
    create table(:channel_tags) do
      add :channel_id, references(:channels)
      add :tag_id, references(:tags, on_delete: :delete_all)
    end

    create unique_index(:channel_tags, [:channel_id, :tag_id])
  end
end
