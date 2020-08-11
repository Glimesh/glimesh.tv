defmodule Glimesh.Repo.Migrations.StreamMetadata do
  use Ecto.Migration

  def change do
      create table(:stream_metadata) do
        add :streamer_id, references(:users, on_delete: :delete_all), null: false
        add :stream_title, :string, default: "Live Stream!"

        timestamps()
      end
  end
end
