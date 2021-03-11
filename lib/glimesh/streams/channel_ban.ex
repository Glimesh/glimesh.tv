defmodule Glimesh.Streams.ChannelBan do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Glimesh.Accounts.User
  alias Glimesh.Streams.Channel

  schema "channel_bans" do
    belongs_to :channel, Channel
    belongs_to :user, User

    field :expires_at, :naive_datetime
    field :reason, :string

    timestamps()
  end

  @doc false
  def changeset(channel_ban, attrs) do
    channel_ban
    |> cast(attrs, [
      :expires_at,
      :reason
    ])
    |> validate_required([:channel, :user])
    |> unique_constraint([:channel_id, :user_id, :expires_at],
      name: "channel_bans_unique_index_non_null"
    )
    |> unique_constraint([:channel_id, :user_id, :expires_at],
      name: "channel_bans_unique_index_null"
    )
  end
end
