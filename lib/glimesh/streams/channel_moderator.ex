defmodule Glimesh.Streams.ChannelModerator do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Glimesh.Accounts.User
  alias Glimesh.Streams.Channel

  schema "channel_moderators" do
    belongs_to :channel, Channel
    belongs_to :user, User

    field :can_short_timeout, :boolean
    field :can_long_timeout, :boolean
    field :can_un_timeout, :boolean
    field :can_ban, :boolean
    field :can_unban, :boolean
    field :can_delete, :boolean

    timestamps()
  end

  @doc false
  def changeset(channel_moderator, attrs) do
    channel_moderator
    |> cast(attrs, [
      :can_short_timeout,
      :can_long_timeout,
      :can_un_timeout,
      :can_ban,
      :can_unban,
      :can_delete
    ])
    |> validate_required([:channel, :user])
    |> unique_constraint([:channel_id, :user_id])
  end
end
