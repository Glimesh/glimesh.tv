defmodule Glimesh.Jobs.AutoHostCron do
  @moduledoc false
  use Oban.Worker

  require Logger

  alias Glimesh.ChannelHostsLookups

  @impl Oban.Worker
  def perform(_) do
    Logger.info("Starting Auto-Host runner")
    start = NaiveDateTime.utc_now()

    case ChannelHostsLookups.recheck_error_status_channels() do
      {:ok, %{rows: _, num_rows: num}} ->
        Logger.info(
          "Auto-Host runner - Changed #{num} of entries from errored back to ready for hosting targets."
        )

      {:error, _} ->
        Logger.error("Auto-Host runner - failed to recheck hosting targets that are in error.")
    end

    case ChannelHostsLookups.unhost_channels_not_live() do
      {:ok, %{rows: _, num_rows: num}} ->
        Logger.info("Auto-Host runner - Un-hosted #{num} of entries for channels no longer live.")

      {:error, _} ->
        Logger.error("Auto-Host runner - failed to un-host channels no longer live.")
    end

    case ChannelHostsLookups.invalidate_hosting_channels_where_necessary() do
      {:ok, %{rows: _, num_rows: num}} ->
        Logger.info(
          "Auto-Host runner - invalidated #{num} of entries for host/target pairs that are no longer valid."
        )

      {:error, _} ->
        Logger.error("Auto-Host runner - failed to invalidate host/target pairs no longer valid.")
    end

    case ChannelHostsLookups.host_some_channels() do
      {:ok, %{rows: _, num_rows: num}} ->
        Logger.info("Auto-Host runner - updated #{num} entries to hosting status.")

      {:error, _} ->
        Logger.error("Auto-Host runner - failed to host any channels")
    end

    complete = NaiveDateTime.utc_now()
    time = NaiveDateTime.diff(complete, start, :millisecond)
    Logger.info("Auto-Host runner finished in #{time} ms")

    :ok
  rescue
    e ->
      {:error, e}
  end
end
