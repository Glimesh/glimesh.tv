defmodule Glimesh.AccountFollows.Follower do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "followers" do
    belongs_to :streamer, Glimesh.Accounts.User
    belongs_to :user, Glimesh.Accounts.User

    field :has_live_notifications, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(followers, attrs \\ %{}) do
    followers
    |> cast(attrs, [:has_live_notifications])
    |> validate_required([:streamer, :user, :has_live_notifications])
    |> unique_constraint([:streamer_id, :user_id])
  end
end
