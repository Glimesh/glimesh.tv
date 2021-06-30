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
  end
end
