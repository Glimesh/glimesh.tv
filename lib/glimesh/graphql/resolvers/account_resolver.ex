defmodule Glimesh.Resolvers.AccountResolver do
  @moduledoc false
  alias Glimesh.AccountFollows
  alias Glimesh.Accounts
  alias Glimesh.Repo

  @error_not_found "Could not find resource"

  # Users

  def myself(_, _, %{context: %{user_access: ua}}) do
    if user = Accounts.get_user(ua.user.id) do
      {:ok, user}
    else
      {:error, @error_not_found}
    end
  end

  def all_users(args, _) do
    Accounts.list_users()
    |> Absinthe.Relay.Connection.from_query(&Repo.all/1, args)
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

  def all_followers(%{streamer_username: streamer_username, user_username: user_username}) do
    streamer = Accounts.get_by_username(streamer_username)
    user = Accounts.get_by_username(user_username)

    if !is_nil(streamer) and !is_nil(user) do
      {:ok, :single, AccountFollows.get_following(streamer, user)}
    else
      {:error, @error_not_found}
    end
  end

  def all_followers(%{streamer_username: streamer_username}) do
    if streamer = Accounts.get_by_username(streamer_username) do
      {:ok, :query, AccountFollows.list_followers(streamer)}
    else
      {:error, @error_not_found}
    end
  end

  def all_followers(%{user_username: user_username}) do
    if user = Accounts.get_by_username(user_username) do
      {:ok, :query, AccountFollows.list_following(user)}
    else
      {:error, @error_not_found}
    end
  end

  def all_followers(%{streamer_id: streamer_id, user_id: user_id}) do
    streamer = Accounts.get_user(streamer_id)
    user = Accounts.get_user(user_id)

    if !is_nil(streamer) and !is_nil(user) do
      {:ok, :single, AccountFollows.get_following(streamer, user)}
    else
      {:error, @error_not_found}
    end
  end

  def all_followers(%{streamer_id: streamer_id}) do
    if streamer = Accounts.get_user(streamer_id) do
      {:ok, :query, AccountFollows.list_followers(streamer)}
    else
      {:error, @error_not_found}
    end
  end

  def all_followers(%{user_id: user_id}) do
    if user = Accounts.get_user(user_id) do
      {:ok, :query, AccountFollows.list_following(user)}
    else
      {:error, @error_not_found}
    end
  end

  def all_followers(_) do
    {:ok, :query, AccountFollows.list_all_follows()}
  end

  def all_followers(args, _) do
    args = Map.put(args, :first, min(Map.get(args, :first), 1000))

    case all_followers(args) do
      {:ok, :query, resp} -> Absinthe.Relay.Connection.from_query(resp, &Repo.all/1, args)
      {:ok, :single, resp} -> Absinthe.Relay.Connection.from_list(resp, args)
      {:error, err} -> {:error, err}
    end
  end
end
