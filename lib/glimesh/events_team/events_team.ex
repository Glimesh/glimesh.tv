defmodule Glimesh.EventsTeam.Event do
  @moduledoc false

  use Ecto.Schema
  use Waffle.Ecto.Schema

  import Ecto.Changeset

  schema "events" do
    field :image, Glimesh.EventImage.Type
    field :type, :string
    field :start_date, :naive_datetime
    field :end_date, :naive_datetime
    field :label, :string
    field :description, :string
    field :featured, :boolean
    field :channel, :string
    timestamps()
  end

  def changeset(event, attrs \\ %{}) do
    event
    |> cast(attrs, [
      :label,
      :start_date,
      :end_date,
      :description,
      :featured,
      :channel,
      :type
    ])
    |> validate_length(:label, max: 250)
    |> validate_length(:description, max: 8192)
    |> cast_attachments(attrs, [:image], allow_paths: true)
  end
end
