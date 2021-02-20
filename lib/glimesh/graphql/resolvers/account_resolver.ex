defmodule Glimesh.Resolvers.AccountResolver do
  @moduledoc false
  alias Glimesh.AccountFollows
  alias Glimesh.Accounts

  # Users

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

  # Followers

  def all_followers(%{streamer_username: streamer_username}, _) do
    streamer = Accounts.get_by_username(streamer_username)
    {:ok, AccountFollows.list_followers(streamer)}
  end

  def all_followers(%{user_username: user_username}, _) do
    user = Accounts.get_by_username(user_username)
    {:ok, AccountFollows.list_following(user)}
  end

  def all_followers(%{streamer_username: streamer_username, user_username: user_username}, _) do
    streamer = Accounts.get_by_username(streamer_username)
    user = Accounts.get_by_username(user_username)
    {:ok, AccountFollows.get_following(streamer, user)}
  end

  def all_followers(_, _) do
    {:ok, AccountFollows.list_all_follows()}
  end
end
