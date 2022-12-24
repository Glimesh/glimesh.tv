defmodule Glimesh.Streams.ChannelBannedRaid do
  @moduledoc false
  use Ecto.Schema
  use Waffle.Ecto.Schema

  import Ecto.Changeset

  schema "channel_banned_raids" do
    belongs_to :channel, Glimesh.Streams.Channel
    belongs_to :banned_channel, Glimesh.Streams.Channel

    timestamps()
  end

  def changeset(%Glimesh.Streams.ChannelBannedRaid{} = banned_raiding_channel, attrs \\ %{}) do
    banned_raiding_channel
    |> cast(attrs, [
      :channel_id,
      :banned_channel_id
    ])
  end

  def insert_new_ban(%Glimesh.Streams.Channel{} = channel, banned_channel_id) do
    changeset(%Glimesh.Streams.ChannelBannedRaid{}, %{
      channel_id: channel.id,
      banned_channel_id: banned_channel_id
    })
    |> Glimesh.Repo.insert()
  end

  def remove_ban(%Glimesh.Streams.ChannelBannedRaid{} = banned_raid) do
    Glimesh.Repo.delete(banned_raid)
  end
end
