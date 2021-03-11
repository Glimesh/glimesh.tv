defmodule Glimesh.Configurations do
  @moduledoc """
  A simple module responsible for various key / value configurations we need.
  """
  import Ecto.Query, warn: false

  alias Glimesh.Configurations.Configuration
  alias Glimesh.Repo

  @doc """
  Get configuration value from the table

  ## Examples

      iex> get_configuration_value("existing_key")
      "Some value"

      iex> get_configuration_value("nonexisting_key")
      nil

  """
  def get_configuration_value(key) do
    Repo.one(
      from c in Configuration,
        where: c.key == ^key,
        limit: 1
    )
    |> case do
      %Configuration{value: value} -> value
      nil -> nil
    end
  end
end
