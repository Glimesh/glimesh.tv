defmodule Glimesh.Payments do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false
  alias Glimesh.Repo

  alias Glimesh.Payments.PlatformSubscription

  @doc """
  Returns the list of platform_subscription.

  ## Examples

      iex> list_platform_subscription()
      [%PlatformSubscription{}, ...]

  """
  def list_platform_subscriptions do
    Repo.all(PlatformSubscription)
  end

  @doc """
  Gets a single platform_subscription.

  Raises `Ecto.NoResultsError` if the Platform subscriptions does not exist.

  ## Examples

      iex> get_platform_subscription!(123)
      %PlatformSubscription{}

      iex> get_platform_subscription!(456)
      ** (Ecto.NoResultsError)

  """
  def get_platform_subscription!(id), do: Repo.get!(PlatformSubscription, id)

  @doc """
  Creates a platform_subscription.

  ## Examples

      iex> create_platform_subscription(%{field: value})
      {:ok, %PlatformSubscription{}}

      iex> create_platform_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_platform_subscription(attrs \\ %{}) do
    %PlatformSubscription{}
    |> PlatformSubscription.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a platform_subscription.

  ## Examples

      iex> update_platform_subscription(platform_subscription, %{field: new_value})
      {:ok, %PlatformSubscription{}}

      iex> update_platform_subscription(platform_subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_platform_subscription(%PlatformSubscription{} = platform_subscription, attrs) do
    platform_subscription
    |> PlatformSubscription.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a platform_subscription.

  ## Examples

      iex> delete_platform_subscription(platform_subscription)
      {:ok, %PlatformSubscription{}}

      iex> delete_platform_subscription(platform_subscription)
      {:error, %Ecto.Changeset{}}

  """
  def delete_platform_subscription(%PlatformSubscription{} = platform_subscription) do
    Repo.delete(platform_subscription)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking platform_subscription changes.

  ## Examples

      iex> change_platform_subscription(platform_subscription)
      %Ecto.Changeset{data: %PlatformSubscription{}}

  """
  def change_platform_subscription(%PlatformSubscription{} = platform_subscription, attrs \\ %{}) do
    PlatformSubscription.changeset(platform_subscription, attrs)
  end
end
