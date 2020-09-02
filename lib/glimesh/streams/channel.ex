defmodule Glimesh.Streams.Channel do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "channels" do
    belongs_to :user, Glimesh.Accounts.User
    belongs_to :category, Glimesh.Streams.Category

    field :title, :string, default: "Live Stream!"
    field :status, :string
    field :language, :string
    field :thumbnail, :string
    field :stream_key, :string
    field :backend, :string

    timestamps()
  end

  def changeset(channel, attrs \\ %{}) do
    channel
    |> cast(attrs, [:title, :category_id, :language, :thumbnail, :stream_key])
  end

  def maybe_put_assoc(changeset, key, value) do
    if value do
      changeset |> put_assoc(key, value)
    else
      changeset
    end
  end
end
