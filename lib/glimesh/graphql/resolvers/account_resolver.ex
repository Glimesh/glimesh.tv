defmodule Glimesh.Resolvers.AccountResolver do
  @moduledoc false
  alias Glimesh.AccountFollows
  alias Glimesh.Accounts

  @error_not_found "Could not find resource"

  # Users

  def myself(_, _, %{context: %{user_access: ua}}) do
    if user = Accounts.get_user(ua.user.id) do
      {:ok, user}
    else
      {:error, @error_not_found}
    end
  end

  def all_users(_, _) do
    {:ok, Accounts.list_users()}
  end

  def find_user(%{id: id}, _) do
    if user = Accounts.get_user(id) do
      {:ok, user}
    else
      {:error, @error_not_found}
    end
  end

  def find_user(%{username: username}, _) do
    if user = Accounts.get_by_username(username) do
      {:ok, user}
    else
      {:error, @error_not_found}
    end
  end

  def find_user(_, _), do: {:error, @error_not_found}

  # Followers

  def all_followers(%{streamer_username: streamer_username, user_username: user_username}, _) do
    streamer = Accounts.get_by_username(streamer_username)
    user = Accounts.get_by_username(user_username)

    if !is_nil(streamer) and !is_nil(user) do
      {:ok, AccountFollows.get_following(streamer, user)}
    else
      {:error, @error_not_found}
    end
  end

  def all_followers(%{streamer_username: streamer_username}, _) do
    if streamer = Accounts.get_by_username(streamer_username) do
      {:ok, AccountFollows.list_followers(streamer)}
    else
      {:error, @error_not_found}
    end
  end

  def all_followers(%{user_username: user_username}, _) do
    if user = Accounts.get_by_username(user_username) do
      {:ok, AccountFollows.list_following(user)}
    else
      {:error, @error_not_found}
    end
  end

  def all_followers(_, _) do
    {:ok, AccountFollows.list_all_follows()}
  end

  def count_followers(%{streamer_username: streamer_username}, _) do
    if streamer = Accounts.get_by_username(streamer_username) do
      {:ok, AccountFollows.count_followers(streamer)}
    else
      {:error, @error_not_found}
    end
  end

  def count_followers(%{user_username: user_username}, _) do
    if user = Accounts.get_by_username(user_username) do
      {:ok, AccountFollows.count_following(user)}
    else
      {:error, @error_not_found}
    end
  end

  def count_followers(_, _) do
    {:ok, AccountFollows.count_all_following()}
  end
end
