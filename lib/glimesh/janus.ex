defmodule Glimesh.Janus do
  @moduledoc """
  Logic to help with Janus
  """
  import Ecto.Query, warn: false

  alias Glimesh.Janus.EdgeRoute
  alias Glimesh.Repo

  @doc """
  Fetches either the closest edge host depending on location, or falls back to a safe globally available alternative.
  """
  def get_closest_edge_location(country) when is_binary(country) do
    if edge = one_edge_by_location(country) do
      edge
    else
      one_good_edge()
    end
  end

  def get_closest_edge_location(_) do
    one_good_edge()
  end

  def all_edge_routes do
    Repo.replica().all(EdgeRoute)
  end

  def create_edge_route(attrs \\ %{}) do
    %EdgeRoute{}
    |> EdgeRoute.changeset(attrs)
    |> Repo.insert()
  end

  defp one_good_edge do
    Repo.one(
      from e in EdgeRoute,
        where: e.available == true,
        order_by: [desc: :priority],
        order_by: fragment("RANDOM()"),
        limit: 1
    )
  end

  defp one_edge_by_location(country) do
    Repo.one(
      from e in EdgeRoute,
        where: e.available == true and ^country in e.country_codes,
        order_by: [desc: :priority],
        order_by: fragment("RANDOM()"),
        limit: 1
    )
  end
end
