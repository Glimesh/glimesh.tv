defmodule Glimesh.Jobs.InteractivePrunerCron do
  @moduledoc false
  use Oban.Worker, max_attempts: 10
  alias Glimesh.Interactive

  # Run every 15 minutes
  @interval 900_000

  # Removes all collected zip files every 15 minutes
  @impl Oban.Worker
  def perform(_) do
    Interactive.cleanup()
    Glimesh.Jobs.InteractivePrunerCron.new(%{}, schedule_in: @interval)
    |> Oban.insert()

    :ok
  rescue
    e ->
      {:error, e}
  end
end
