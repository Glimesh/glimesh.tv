defmodule Glimesh.Oauth.ResourceOwners do
  @moduledoc false

  @behaviour Boruta.Oauth.ResourceOwners

  alias Boruta.Oauth.ResourceOwner
  alias Glimesh.Accounts.User
  alias Glimesh.Repo

  @impl Boruta.Oauth.ResourceOwners
  def get_by(username: username) do
    case Repo.get_by(User, username: username) do
      %User{id: id, username: username} ->
        {:ok, %ResourceOwner{sub: Integer.to_string(id), username: username}}

      _ ->
        {:error, "User not found."}
    end
  end

  def get_by(sub: sub) do
    case Repo.get_by(User, id: String.to_integer(sub)) do
      %User{id: id, username: username} ->
        {:ok, %ResourceOwner{sub: Integer.to_string(id), username: username}}

      _ ->
        {:error, "User not found."}
    end
  end

  def get_from(%Boruta.Oauth.ResourceOwner{} = resource_owner) do
    case resource_owner do
      %{username: username} -> Repo.get_by(User, username: username)
      %{sub: sub} -> Repo.get_by(User, id: String.to_integer(sub))
      _ -> nil
    end
  end

  @impl Boruta.Oauth.ResourceOwners
  def check_password(resource_owner, password) do
    user = Glimesh.Accounts.get_by_username(resource_owner.username)

    if User.valid_password?(user, password) do
      :ok
    else
      {:error, "Invalid password or username."}
    end
  end

  @impl Boruta.Oauth.ResourceOwners
  def authorized_scopes(%ResourceOwner{}), do: []
end
