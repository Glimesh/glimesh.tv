defmodule Glimesh.Jobs.HomepageCron do
  @moduledoc false
  use Oban.Worker, max_attempts: 10

  require Logger

  # 5 Minutes
  @interval 300_000

  @impl Oban.Worker
  def perform(_) do
    Logger.info("Generating homepage")
    Glimesh.Homepage.update_homepage()

    Glimesh.Jobs.HomepageCron.new(%{}, schedule_in: @interval)
    |> Oban.insert()

    :ok
  rescue
    e ->
      {:error, e}
  end
end
