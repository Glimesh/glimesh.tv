defmodule Glimesh.Janus.EdgeRoute do
  @moduledoc """
  Represents a routing location
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "janus_edge_routes" do
    field :hostname, :string
    field :url, :string
    field :priority, :float, default: 1.00
    field :available, :boolean
    field :country_codes, {:array, :string}

    timestamps()
  end

  @doc false
  def changeset(janus_edge_route, attrs) do
    janus_edge_route
    |> cast(attrs, [
      :hostname,
      :url,
      :priority,
      :available,
      :country_codes
    ])
    |> validate_required([:hostname, :available])
  end
end
