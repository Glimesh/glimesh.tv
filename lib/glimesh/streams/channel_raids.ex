defmodule Glimesh.Streams.ChannelRaids do
  @moduledoc false

  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  schema "channel_raids" do
    field :group_id, Ecto.UUID
    field :status, Ecto.Enum, values: [:pending, :complete, :cancelled], default: :pending

    belongs_to :started_by, Glimesh.Accounts.User
    belongs_to :target_channel, Glimesh.Streams.Channel

    timestamps()
  end

  @doc false
  def changeset(raid, attrs) do
    raid
    |> cast(attrs, [
      :group_id,
      :status
    ])
    |> validate_required([:group_id, :status, :started_by, :target_channel])
    |> unique_constraint([:group_id])
  end
end
