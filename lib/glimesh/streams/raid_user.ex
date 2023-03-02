defmodule Glimesh.Streams.RaidUser do
  @moduledoc false

  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  schema "raid_users" do
    field :status, Ecto.Enum, values: [:pending, :complete, :cancelled]

    belongs_to :group, Glimesh.Streams.ChannelRaids, references: :group_id, type: Ecto.UUID
    belongs_to :user, Glimesh.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [
      :status
    ])
    |> cast_assoc(:user, with: &Glimesh.Accounts.User.registration_changeset/2)
    |> cast_assoc(:group)
    |> validate_required([:group, :user])
  end
end
