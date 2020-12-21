defmodule Glimesh.Resolvers.AccountResolver do
  @moduledoc false
  alias Glimesh.Accounts

  def myself(_, _, %{context: %{user_access: ua}}) do
    {:ok, Accounts.get_user!(ua.user.id)}
  end

  def all_users(_, _) do
    {:ok, Accounts.list_users()}
  end

  def find_user(%{id: id}, _) do
    {:ok, Accounts.get_user!(id)}
  end

  def find_user(%{username: username}, _) do
    {:ok, Accounts.get_by_username!(username)}
  end
end
