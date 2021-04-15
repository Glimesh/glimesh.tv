defmodule Glimesh.Streams.HomepageChannel do
  @moduledoc false
  use Ecto.Schema
  use Waffle.Ecto.Schema

  schema "homepage_channels" do
    belongs_to :channel, Glimesh.Streams.Channel

    field :slot_started_at, :naive_datetime
    field :slot_ended_at, :naive_datetime

    timestamps()
  end
end
