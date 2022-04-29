defmodule Glimesh.Jobs.StreamPrunerCron do
  @moduledoc false
  @behaviour Rihanna.Job

  require Logger

  alias Glimesh.ChannelLookups
  alias Glimesh.Streams

  # 5 Minutes in milliseconds
  @interval 300_000
  # 5 Minutes in seconds
  @prune_diff 300

  def priority, do: 17

  def perform(_) do
    channels = ChannelLookups.list_live_channels()
    Logger.info("Checking for stale streams to prune")

    current_time = NaiveDateTime.local_now()

    Enum.each(channels, fn channel ->
      last_time =
        case Streams.get_last_stream_metadata(channel.stream) do
          nil ->
            # No stream metadata yet, let's compare started_at
            channel.stream.started_at

          %Glimesh.Streams.StreamMetadata{} = metadata ->
            metadata.inserted_at
        end

      if NaiveDateTime.diff(current_time, last_time, :second) > @prune_diff do
        Logger.info("Pruning stale stream #{channel.stream.id}")
        Streams.end_stream(channel.stream)
      end
    end)

    Rihanna.schedule(Glimesh.Jobs.StreamPrunerCron, [], in: @interval)

    :ok
  rescue
    e ->
      {:error, e}
  end

  def retry_at(_failure_reason, _args, attempts) when attempts < 10 do
    seconds = attempts * 5
    due_at = DateTime.add(DateTime.utc_now(), seconds, :second)
    Logger.info("StreamPrunerCron failed, retrying in #{seconds}")
    {:ok, due_at}
  end

  def retry_at(_failure_reason, _args, _attempts) do
    Logger.error("StreamPrunerCron failed after 10 attempts")
    :noop
  end
end
