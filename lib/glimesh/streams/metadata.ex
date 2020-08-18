defmodule Glimesh.Streams.Metadata do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  alias Glimesh.Accounts.User

  schema "stream_metadata" do
    belongs_to :streamer, Glimesh.Accounts.User
    belongs_to :category, Glimesh.Streams.Category

    field :stream_title, :string, default: "Live Stream!"

    timestamps()
  end

  def changeset(stream_metadata, attrs \\ %{}) do
    stream_metadata
    |> cast(attrs, [:stream_title, :category_id])
  end

  def maybe_put_assoc(changeset, key, value) do
    if value do
      changeset |> put_assoc(key, value)
    else
      changeset
    end
  end
end
