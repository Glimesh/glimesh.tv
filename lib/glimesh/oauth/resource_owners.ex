defmodule Glimesh.Oauth.ResourceOwners do
  @behaviour Boruta.Oauth.ResourceOwners

  alias Boruta.Oauth.ResourceOwner
  alias Glimesh.Accounts.User
  alias Glimesh.Repo

  @impl Boruta.Oauth.ResourceOwners
  def get_by(username: username) do
    with %User{id: id, username: username} <- Repo.get_by(User, username: username) do
      {:ok, %ResourceOwner{sub: Integer.to_string(id), username: username}}
    else
      _ -> {:error, "User not found."}
    end
  end

  def get_by(sub: sub) do
    with %User{id: id, username: username} <- Repo.get_by(User, id: String.to_integer(sub)) do
      {:ok, %ResourceOwner{sub: Integer.to_string(id), username: username}}
    else
      _ -> {:error, "User not found."}
    end
  end

  @impl Boruta.Oauth.ResourceOwners
  def check_password(resource_owner, password) do
    IO.inspect(resource_owner)
    user = nil
    User.valid_password?(user, password)
  end

  @impl Boruta.Oauth.ResourceOwners
  def authorized_scopes(%ResourceOwner{}), do: []
end
