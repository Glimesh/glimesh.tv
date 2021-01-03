defmodule Glimesh.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    topologies = [
      example: [
        strategy: Cluster.Strategy.Epmd,
        config: [
          hosts: [
            :"glimesh@do-nyc3-web1.us-east.web.glimesh.tv",
            :"glimesh@do-nyc3-web2.us-east.web.glimesh.tv"
          ]
        ]
      ]
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
      # Start a worker by calling: Glimesh.Worker.start_link(arg)
      {Absinthe.Subscription, GlimeshWeb.Endpoint},
      Glimesh.Workers.StreamMetrics,
      Glimesh.Workers.StreamPruner
      # {Glimesh.Worker, arg}
    ]

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
