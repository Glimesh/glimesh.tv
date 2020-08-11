defmodule Glimesh.Streams.StreamMetadata do
  use Ecto.Schema
  import Ecto.Changeset
  alias Glimesh.Accounts.User

  schema "stream_metadata" do
    belongs_to :streamer, Glimesh.Accounts.User

    field :stream_title, :string, default: "Live Stream!"

    timestamps()
  end

  def title_changeset(stream_metadata, attrs) do
    IO.inspect(stream_metadata)
    stream_metadata
    |> cast(attrs, [:stream_title])
  end

end
