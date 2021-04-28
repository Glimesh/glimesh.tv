defmodule Glimesh.Api do
  @moduledoc """
  The Glimesh API uses GraphQL endpoints to serve data. Mostly intended for 3rd party clients and our mobile app.
  """
  alias Absinthe.Relay.Connection
  alias Glimesh.Repo

  @error_not_found "Could not find resource"
  @error_access_denied "Access denied"

  def error_not_found, do: {:error, @error_not_found}

  def error_access_denied, do: {:error, @error_access_denied}

  @doc """
  Return a Connection.from_query with a count (if last is specified).
  """
  def connection_from_query_with_count(query, args, options \\ []) do
    options =
      if Map.has_key?(args, :last) do
        # Only count records if we're starting at the end
        Keyword.put(options, :count, Repo.aggregate(query, :count, :id))
      else
        options
      end

    # Set a complete max of 1000 records
    options = Keyword.put(options, :max, 1000)

    # If the user didn't select an order, just give them the first 100
    args =
      if Map.has_key?(args, :first) == false and Map.has_key?(args, :last) == false do
        Map.put(args, :first, 100)
      else
        args
      end

    Connection.from_query(query, &Repo.all/1, args, options)
  end

  @doc """
  Parse a list of changeset errors into actionable API errors
  """
  def parse_ecto_changeset_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
