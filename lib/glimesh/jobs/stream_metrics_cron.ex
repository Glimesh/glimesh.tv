defmodule Glimesh.Jobs.StreamMetricsCron do
  @moduledoc false
  @behaviour Rihanna.Job

  require Logger

  alias Glimesh.ChannelLookups
  alias Glimesh.Streams

  @interval 60_000

  def perform(_) do
    channels = ChannelLookups.list_live_channels()
    Logger.info("Counting live viewers for #{length(channels)} channels")

    Enum.each(channels, fn channel ->
      count_viewers =
        Streams.get_subscribe_topic(:viewers, channel.id)
        |> Glimesh.Presence.list_presences()
        |> Enum.count()

      Streams.update_stream(channel.stream, %{
        count_viewers: count_viewers,
        peak_viewers: max(channel.stream.count_viewers, count_viewers)
      })
    end)

    Rihanna.schedule(Glimesh.Jobs.StreamMetricsCron, [], in: @interval)

    :ok
  end
end
