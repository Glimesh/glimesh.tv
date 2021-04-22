defmodule Glimesh.Workers.StreamMetrics do
  @moduledoc """
  Periodic metric aggregator for live stream information
  """
  use GenServer

  require Logger
  alias Glimesh.ChannelLookups
  alias Glimesh.Streams

  @interval 60_000

  def start_link(_init_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Process.send_after(self(), :count_viewers, @interval)
    {:ok, %{last_run_at: nil}}
  end

  def handle_info(:count_viewers, _state) do
    count_current_viewers()
    Process.send_after(self(), :count_viewers, @interval)

    {:noreply, %{last_run_at: :calendar.local_time()}}
  end

  defp count_current_viewers do
    channels = ChannelLookups.list_live_channels()
    Logger.info("Counting live viewers for #{length(channels)} channels")

    Enum.map(channels, fn channel ->
      count_viewers =
        Streams.get_subscribe_topic(:viewers, channel.id)
        |> Glimesh.Presence.list_presences()
        |> Enum.count()

      Streams.update_stream(channel.stream, %{
        count_viewers: count_viewers,
        peak_viewers: max(channel.stream.count_viewers, count_viewers)
      })
    end)
  end
end
