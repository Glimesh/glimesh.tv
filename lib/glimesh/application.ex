defmodule Glimesh.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies)

    children = [
      Glimesh.PromEx,
      {Cluster.Supervisor, [topologies, [name: Glimesh.ClusterSupervisor]]},
      # Start the Ecto repository
      Glimesh.Repo,
      Glimesh.Repo.ReadReplica,
      # Start the Telemetry supervisor
      GlimeshWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Glimesh.PubSub},
      # Who and where are you?
      Glimesh.Presence,
      # Start the Endpoint (http/https)
      GlimeshWeb.Endpoint,
      {Rihanna.Supervisor, [postgrex: Glimesh.Repo.config()]},
      {ConCache,
       [
         name: Glimesh.QueryCache.name(),
         ttl_check_interval: :timer.seconds(5),
         global_ttl: :timer.seconds(30)
       ]},
      {Absinthe.Subscription, GlimeshWeb.Endpoint}
    ]

    GlimeshWeb.ApiLogger.start_logger()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Glimesh.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    GlimeshWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
