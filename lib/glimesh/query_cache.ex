defmodule Glimesh.QueryCache do
  @moduledoc """
  Wrapper functions for caching query results for read-only non-user-specific queries.
  """

  @doc """
  Atom used for refencing the query cache
  """
  @spec name :: :glimesh_query_cache
  def name, do: :glimesh_query_cache

  @doc """
  Retrieves the item from the cache, or inserts the new item. Will raise if the
  called lambda function does not return {:ok, val}

  If the item exists in the cache, it is retrieved. Otherwise, the lambda
  function is executed and its result is stored under the given key.

  ## Examples

      iex> get_and_store!("some_key", fn x -> :timer.sleep(1000) end)
      # ... 1 second pause
      :ok

      iex> get_and_store!("some_key", fn x -> :timer.sleep(1000) end)
      # ... immediate return
      :ok
  """
  @spec get_and_store!(any, (() -> {:error, any} | {:ok, any})) :: any
  def get_and_store!(key, function) do
    case ConCache.fetch_or_store(name(), key, function) do
      {:ok, result} -> result
      {:error, error} -> raise(error)
    end
  end
end
