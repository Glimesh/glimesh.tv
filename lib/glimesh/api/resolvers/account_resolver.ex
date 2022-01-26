defmodule Glimesh.Api.AccountResolver do
  @moduledoc false
  import Ecto.Query

  alias Absinthe.Relay.Connection
  alias Glimesh.AccountFollows
  alias Glimesh.Accounts
  alias Glimesh.Api
  alias Glimesh.ChannelLookups

  @error_not_found "Could not find resource"

  # Query Field Resolvers
  def resolve_email(user, _, %{context: %{access: access}}) do
    with :ok <- Bodyguard.permit(Api.Scopes, :email, access, user) do
      {:ok, user.email}
    end
  end

  def resolve_avatar_url(user, _, _) do
    {:ok, Api.resolve_full_url(Glimesh.Avatar.url({user.avatar, user}))}
  end

  # Users
  def myself(_, _, %{context: %{access: access}}) do
    if user = Accounts.get_user(access.user.id) do
      {:ok, user}
    else
      {:error, @error_not_found}
    end
  end

  def follow_channel(
        _parent,
        %{channel_id: channel_id, live_notifications: live_notifications},
        %{context: %{access: access}}
      ) do
    with :ok <- Bodyguard.permit(Glimesh.Api.Scopes, :follow, access),
         channel when channel != nil <- ChannelLookups.get(channel_id, [:user]),
         streamer when streamer != nil <- Accounts.get_user(channel.user.id),
         user when user != nil <- Accounts.get_user(access.user.id),
         {:ok, following} <- AccountFollows.follow(streamer, user, live_notifications) do
      {:ok, following}
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, Api.parse_ecto_changeset_errors(changeset)}

      {:error, message} when is_binary(message) ->
        {:error, message}

      nil ->
        {:error, @error_not_found}

      _ ->
        {:error, "Unknown error."}
    end
  end

  def update_follow(
        _parent,
        %{channel_id: channel_id, live_notifications: live_notifications},
        %{context: %{access: access}}
      ) do
    with :ok <- Bodyguard.permit(Glimesh.Api.Scopes, :follow, access),
         channel when channel != nil <- Glimesh.ChannelLookups.get(channel_id, [:user]),
         following when following != nil <-
           AccountFollows.get_following(channel.user, access.user) do
      AccountFollows.update_following(following, %{
        has_live_notifications: live_notifications
      })
    else
      {:ok, following} ->
        {:ok, following}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, Api.parse_ecto_changeset_errors(changeset)}

      {:error, message} when is_binary(message) ->
        {:error, message}

      nil ->
        {:error, @error_not_found}

      _ ->
        {:error, "Unknown error."}
    end
  end

  def unfollow_channel(
        _parent,
        %{channel_id: channel_id},
        %{context: %{access: access}}
      ) do
    with :ok <- Bodyguard.permit(Glimesh.Api.Scopes, :follow, access),
         channel when channel != nil <- Glimesh.ChannelLookups.get(channel_id, [:user]),
         streamer when streamer != nil <- Accounts.get_user(channel.user.id),
         user when user != nil <- Accounts.get_user(access.user.id) do
      AccountFollows.unfollow(streamer, user)
    else
      {:ok, following} ->
        {:ok, following}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, Api.parse_ecto_changeset_errors(changeset)}

      {:error, message} when is_binary(message) ->
        {:error, message}

      nil ->
        {:error, @error_not_found}

      _ ->
        {:error, "Unknown error."}
    end
  end

  def all_users(args, _) do
    Accounts.query_users()
    |> order_by(:id)
    |> Api.connection_from_query_with_count(args)
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
  def all_followers(args, _) do
    case query_followers(args) do
      {:ok, :query, resp} -> Api.connection_from_query_with_count(resp, args)
      {:ok, :single, resp} -> Connection.from_list([resp], args)
      {:error, err} -> {:error, err}
    end
  end

  defp query_followers(%{streamer_id: streamer_id, user_id: user_id}) do
    streamer = Accounts.get_user(streamer_id)
    user = Accounts.get_user(user_id)

    if !is_nil(streamer) and !is_nil(user) do
      {:ok, :single, AccountFollows.get_following(streamer, user)}
    else
      {:error, @error_not_found}
    end
  end

  defp query_followers(%{streamer_id: streamer_id}) do
    if streamer = Accounts.get_user(streamer_id) do
      followers =
        AccountFollows.query_followers(streamer)
        |> order_by(:id)

      {:ok, :query, followers}
    else
      {:error, @error_not_found}
    end
  end

  defp query_followers(%{user_id: user_id}) do
    if user = Accounts.get_user(user_id) do
      following =
        AccountFollows.query_following(user)
        |> order_by(:id)

      {:ok, :query, following}
    else
      {:error, @error_not_found}
    end
  end

  defp query_followers(_) do
    followers =
      AccountFollows.query_all_follows()
      |> order_by(:id)

    {:ok, :query, followers}
  end

  def get_user_followers(args, %{source: user}) do
    Glimesh.AccountFollows.Follower
    |> where(streamer_id: ^user.id)
    |> order_by(:id)
    |> Api.connection_from_query_with_count(args)
  end

  def get_user_following(args, %{source: user}) do
    Glimesh.AccountFollows.Follower
    |> where(user_id: ^user.id)
    |> order_by(:id)
    |> Api.connection_from_query_with_count(args)
  end

  def get_live_user_following_channels(args, %{source: user}) do
    following_user_ids =
      Enum.map(Glimesh.AccountFollows.list_following(user), fn x -> x.streamer_id end)

    Glimesh.Streams.Channel
    |> where([c], c.user_id in ^following_user_ids)
    |> where([c], c.status == "live")
    |> order_by(:id)
    |> Api.connection_from_query_with_count(args)
  end
end
