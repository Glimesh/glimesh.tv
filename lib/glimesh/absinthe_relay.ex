defmodule Glimesh.AbsintheRelay do
  use GenServer

  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def create_relay(server, phoenix_topic, absinthe_topic) do
    GenServer.call(server, {:register, phoenix_topic, absinthe_topic})
  end

  ## GenServer

  def subscribe_and_relay(elixir_topic, absinthe_topic) do
    Absinthe.Subscription.publish(MyAppWeb.Endpoint, comment,
      comment_added: "absinthe-graphql/absinthe"
    )
  end

  def handle_cast({:register, phoenix_topic, absinthe_topic}, registry) do
    if Map.has_key?(registry, phoenix_topic) do
      {:noreply, registry}
    else
      {:noreply, Map.put(registry, phoenix_topic, absinthe_topic)}
    end
  end

  def handle_info({event, data}, whatever) do
    IO.inspect(["RELAY", event, data, whatever])

    Absinthe.Subscription.publish(GlimeshWeb.Endpoint, data, absinthe_mutation: absinthe_topic)

    {:noreply, whatever}
  end
end
