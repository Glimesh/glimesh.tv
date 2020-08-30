defmodule Glimesh.Doop do
  use GenServer

  alias Glimesh.Streams

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    Streams.subscribe_to(:channel, 1)

    {:ok, %{}}
  end

  @impl true
  def handle_info({:update_channel, data}, whatever) do
    IO.inspect(["GOTTEM", data])

    {:noreply, whatever}
  end
end
