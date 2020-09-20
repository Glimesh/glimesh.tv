defmodule Glimesh.Streams.ChannelModerationLog do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Glimesh.Accounts.User
  alias Glimesh.Streams.Channel

  schema "channel_moderation_log" do
    belongs_to :channel, Channel
    belongs_to :moderator, User
    belongs_to :user, User
    field :action, :string

    timestamps()
  end

  @doc false
  def changeset(channel_moderation_log, attrs) do
    channel_moderation_log
    |> cast(attrs, [:action])
    |> validate_required([:channel, :moderator, :user, :action])
  end
end
