defmodule Glimesh.Api do
  @moduledoc """
  The Glimesh API uses GraphQL endpoints to serve data. Mostly intended for 3rd party clients and our mobile app.
  """
  @error_not_found "Could not find resource"
  @error_access_denied "Access denied"

  def error_not_found, do: {:error, @error_not_found}

  def error_access_denied, do: {:error, @error_access_denied}

  @doc """
  Parse a list of changset errors into actionable API errors
  """
  def parse_ecto_changeset_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
