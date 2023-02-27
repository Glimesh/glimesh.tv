defmodule Glimesh.Jobs.StartStreamNotifier do
  @moduledoc false
  use Oban.Worker

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"channel_id" => channel_id}}) do
    channel = Glimesh.ChannelLookups.get_channel!(channel_id)
    users = Glimesh.ChannelLookups.list_live_subscribed_followers(channel)
    full_channel = Glimesh.Repo.preload(channel, [:user, :stream, :tags])

    # There's a chance the stream has already gone offline before the email is triggered.
    if Glimesh.Streams.is_live?(full_channel) do
      Glimesh.Streams.ChannelNotifier.deliver_live_channel_notifications(
        users,
        full_channel
      )
    end

    :ok
  end
end
