defmodule Glimesh.Jobs.StartStreamNotifier do
  @moduledoc false
  @behaviour Rihanna.Job

  def perform([channel_id]) do
    channel = Glimesh.ChannelLookups.get_channel!(channel_id)
    users = Glimesh.ChannelLookups.list_live_subscribed_followers(channel)

    Glimesh.Streams.ChannelNotifier.deliver_live_channel_notifications(
      users,
      Glimesh.Repo.preload(channel, [:user, :stream, :tags])
    )

    :ok
  end
end
