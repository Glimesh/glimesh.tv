defmodule Glimesh.Jobs.HomepageCron do
  @moduledoc false
  @behaviour Rihanna.Job

  require Logger

  # 5 Minutes
  @interval 300_000

  def perform(_) do
    Logger.info("Generating homepage")
    Glimesh.Homepage.update_homepage()

    Rihanna.schedule(Glimesh.Jobs.HomepageCron, [], in: @interval)

    :ok
  rescue
    e ->
      {:error, e}
  end

  def retry_at(_failure_reason, _args, attempts) when attempts < 10 do
    seconds = attempts * 5
    due_at = DateTime.add(DateTime.utc_now(), seconds, :second)
    Logger.info("HomepageCron failed, retrying in #{seconds}")
    {:ok, due_at}
  end

  def retry_at(_failure_reason, _args, _attempts) do
    Logger.error("HomepageCron failed after 10 attempts")
    :noop
  end
end
