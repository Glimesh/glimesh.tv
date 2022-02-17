defmodule Glimesh.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :glimesh,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10

  # Read Replicas
  if Mix.env() == :test do
    def replica, do: __MODULE__
  else
    def replica do
      # Switch this back to random when we have more than one replica
      # Enum.random(@replicas)
      Glimesh.Repo.ReadReplica
    end
  end

  @replicas [
    Glimesh.Repo.ReadReplica
  ]

  for repo <- @replicas do
    defmodule repo do
      use Ecto.Repo,
        otp_app: :glimesh,
        adapter: Ecto.Adapters.Postgres,
        read_only: true
    end
  end

  def data do
    Dataloader.Ecto.new(Glimesh.Repo.ReadReplica)
  end
end
