defmodule Glimesh.Jobs.IsNewStreamerFlagger do
  @moduledoc false
  use Oban.Worker

  require Logger

  alias Glimesh.ChannelLookups

  @impl Oban.Worker
  def perform(_) do
    Logger.info("Starting New Streamer Flagger runner")
    start = NaiveDateTime.utc_now()

    {rows, _} = ChannelLookups.clear_new_channel_flags()
    Logger.info("New Streamer Flagger cleared #{rows} flags to false")

    {setrows, _} = ChannelLookups.set_new_channel_flags()
    Logger.info("New Streamer Flagger set #{setrows} flags to true")

    {clearrows, _} =
      ChannelLookups.clear_new_channel_flags_for_channels_with_fifty_hours_or_more()

    Logger.info("New Streamer Flagger cleared #{clearrows} flags on 50 hour or greater channels")

    complete = NaiveDateTime.utc_now()
    time = NaiveDateTime.diff(complete, start, :millisecond)
    Logger.info("New Streamer Flagger runner finished in #{time} ms")

    :ok
  rescue
    e ->
      {:error, e}
  end
end
