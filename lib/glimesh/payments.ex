defmodule Glimesh.Payments do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false
  alias Glimesh.Repo

  alias Glimesh.Payments.PlatformSubscriptions

  @doc """
  Returns the list of platform_subscriptions.

  ## Examples

      iex> list_platform_subscriptions()
      [%PlatformSubscriptions{}, ...]

  """
  def list_platform_subscriptions do
    Repo.all(PlatformSubscriptions)
  end

  @doc """
  Gets a single platform_subscriptions.

  Raises `Ecto.NoResultsError` if the Platform subscriptions does not exist.

  ## Examples

      iex> get_platform_subscriptions!(123)
      %PlatformSubscriptions{}

      iex> get_platform_subscriptions!(456)
      ** (Ecto.NoResultsError)

  """
  def get_platform_subscriptions!(id), do: Repo.get!(PlatformSubscriptions, id)

  @doc """
  Creates a platform_subscriptions.

  ## Examples

      iex> create_platform_subscriptions(%{field: value})
      {:ok, %PlatformSubscriptions{}}

      iex> create_platform_subscriptions(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_platform_subscriptions(attrs \\ %{}) do
    %PlatformSubscriptions{}
    |> PlatformSubscriptions.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a platform_subscriptions.

  ## Examples

      iex> update_platform_subscriptions(platform_subscriptions, %{field: new_value})
      {:ok, %PlatformSubscriptions{}}

      iex> update_platform_subscriptions(platform_subscriptions, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_platform_subscriptions(%PlatformSubscriptions{} = platform_subscriptions, attrs) do
    platform_subscriptions
    |> PlatformSubscriptions.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a platform_subscriptions.

  ## Examples

      iex> delete_platform_subscriptions(platform_subscriptions)
      {:ok, %PlatformSubscriptions{}}

      iex> delete_platform_subscriptions(platform_subscriptions)
      {:error, %Ecto.Changeset{}}

  """
  def delete_platform_subscriptions(%PlatformSubscriptions{} = platform_subscriptions) do
    Repo.delete(platform_subscriptions)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking platform_subscriptions changes.

  ## Examples

      iex> change_platform_subscriptions(platform_subscriptions)
      %Ecto.Changeset{data: %PlatformSubscriptions{}}

  """
  def change_platform_subscriptions(%PlatformSubscriptions{} = platform_subscriptions, attrs \\ %{}) do
    PlatformSubscriptions.changeset(platform_subscriptions, attrs)
  end
end
