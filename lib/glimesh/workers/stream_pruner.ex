defmodule Glimesh.Workers.StreamPruner do
  @moduledoc """
  Periodic stream pruning just in case Janus crashed and didn't send us a stop message
  """
  use GenServer

  require Logger
  alias Glimesh.ChannelLookups
  alias Glimesh.Streams

  # 5 Minutes in milliseconds
  @interval 300_000
  # 5 Minutes in seconds
  @prune_diff 300

  def start_link(_init_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Process.send_after(self(), :prune_streams, @interval)
    {:ok, %{last_run_at: nil}}
  end

  def handle_info(:prune_streams, _state) do
    prune_old_streams()
    Process.send_after(self(), :prune_streams, @interval)

    {:noreply, %{last_run_at: :calendar.local_time()}}
  end

  defp prune_old_streams do
    channels = ChannelLookups.list_live_channels()
    Logger.info("Checking for stale streams to prune")

    current_time = NaiveDateTime.local_now()

    Enum.map(channels, fn channel ->
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
  end
end
