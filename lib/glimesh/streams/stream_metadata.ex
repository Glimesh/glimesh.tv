defmodule Glimesh.Streams.StreamMetadata do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "stream_metadata" do
    belongs_to :stream, Glimesh.Streams.Stream

    field :ingest_server, :string
    field :ingest_viewers, :integer
    field :stream_time_seconds, :integer

    field :source_bitrate, :integer
    field :source_ping, :integer

    field :recv_packets, :integer
    field :lost_packets, :integer
    field :nack_packets, :integer

    field :vendor_name, :string
    field :vendor_version, :string

    field :video_codec, :string
    field :video_height, :integer
    field :video_width, :integer
    field :audio_codec, :string

    timestamps()
  end

  def changeset(stream_metadata, attrs \\ %{}) do
    stream_metadata
    |> cast(attrs, [
      :ingest_server,
      :ingest_viewers,
      :stream_time_seconds,
      :source_bitrate,
      :source_ping,
      :recv_packets,
      :lost_packets,
      :nack_packets,
      :vendor_name,
      :vendor_version,
      :video_codec,
      :video_height,
      :video_width,
      :audio_codec
    ])
    |> cast_assoc(:stream)
    |> validate_required([:stream])
  end
end
