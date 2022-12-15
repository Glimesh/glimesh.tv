defmodule Glimesh.Jobs.HomepageCron do
  @moduledoc false
  use Oban.Worker, max_attempts: 10

  require Logger

  @impl Oban.Worker
  def perform(_) do
    Logger.info("Generating homepage")
    Glimesh.Homepage.update_homepage()

    :ok
  rescue
    e ->
      {:error, e}
  end
end
