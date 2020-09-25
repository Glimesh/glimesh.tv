defmodule Glimesh.Repo.Migrations.AddStreamIdToChannelAndMetadata do
  use Ecto.Migration

  def change do
    alter table(:channels) do
      add :stream_id, references(:streams)
    end

    create table(:stream_metadata) do
      add :stream_id, references(:streams, on_delete: :delete_all), null: false

      add :ingest_server, :string
      add :ingest_viewers, :integer

      add :source_bitrate, :integer
      add :source_ping, :integer

      add :recv_packets, :integer
      add :lost_packets, :integer
      add :nack_packets, :integer

      add :vendor_name, :string
      add :vendor_version, :string

      add :video_codec, :string
      add :video_height, :integer
      add :video_width, :integer
      add :audio_codec, :string

      timestamps
    end
  end
end
