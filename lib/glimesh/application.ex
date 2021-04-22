defmodule Glimesh.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies)
    start_workers = Application.get_env(:glimesh, :start_workers)

    server_children = [
      Glimesh.Workers.StreamMetrics,
      Glimesh.Workers.StreamPruner,
      Glimesh.Workers.HomepageGenerator
    ]

    server_children = [
      Glimesh.Workers.StreamMetrics,
      Glimesh.Workers.StreamPruner
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: Glimesh.ClusterSupervisor]]},
      # Start the Ecto repository
      Glimesh.Repo,
      # Start the Telemetry supervisor
      GlimeshWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Glimesh.PubSub},
      # Who and where are you?
      Glimesh.Presence,
      # Start the Endpoint (http/https)
      GlimeshWeb.Endpoint,
      {ConCache,
       [
         name: Glimesh.QueryCache.name(),
         ttl_check_interval: :timer.seconds(5),
         global_ttl: :timer.seconds(30)
       ]},
      {Absinthe.Subscription, GlimeshWeb.Endpoint}
    ]

    GlimeshWeb.ApiLogger.start_logger()
    Application.ensure_all_started(:appsignal)

    children =
      if start_workers or !is_nil(Application.get_env(:glimesh, GlimeshWeb.Endpoint)[:server]) do
        children ++ server_children
      else
        children
      end

    children =
      if Application.get_env(:glimesh, GlimeshWeb.Endpoint)[:server] do
        children ++ server_children
      else
        children
      end

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
