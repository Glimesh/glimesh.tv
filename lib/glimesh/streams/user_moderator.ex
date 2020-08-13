defmodule Glimesh.Streams.UserModerator do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Glimesh.Accounts.User

  schema "user_moderators" do
    belongs_to :streamer, User
    belongs_to :user, User
    field :can_short_timeout, :boolean
    field :can_long_timeout, :boolean
    field :can_un_timeout, :boolean
    field :can_ban, :boolean
    field :can_unban, :boolean

    timestamps()
  end

  @doc false
  def changeset(user_moderator, attrs) do
    user_moderator
    |> cast(attrs, [
      :can_short_timeout,
      :can_long_timeout,
      :can_un_timeout,
      :can_ban,
      :can_unban
    ])
    |> validate_required([:streamer, :user])
    |> unique_constraint([:streamer_id, :user_id])
  end
end
