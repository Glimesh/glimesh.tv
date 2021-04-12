defmodule Glimesh.Workers.HomepageGenerator do
  @moduledoc """
  Check for homepage updates every 5 minutes
  """
  use GenServer

  require Logger

  @interval 5 * 60_000

  def start_link(_init_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    Process.send_after(self(), :check_homepage, @interval)
    {:ok, %{last_run_at: nil}}
  end

  def handle_info(:check_homepage, _state) do
    Logger.info("Generating homepage")
    Glimesh.Homepage.update_homepage()
    Process.send_after(self(), :check_homepage, @interval)

    {:noreply, %{last_run_at: :calendar.local_time()}}
  end
end
