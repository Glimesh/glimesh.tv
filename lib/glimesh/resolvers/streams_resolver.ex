defmodule Glimesh.Resolvers.StreamsResolver do
  @moduledoc false
  alias Glimesh.Accounts
  alias Glimesh.Payments
  alias Glimesh.Streams

  # Channels

  def all_channels(_, _) do
    {:ok, Streams.list_channels()}
  end

  def find_channel(%{username: username}, _) do
    {:ok, Streams.get_channel_for_username!(username)}
  end

  # Categories

  def all_categories(_, _) do
    {:ok, Streams.list_categories()}
  end

  def find_category(%{slug: slug}, _) do
    {:ok, Streams.get_category!(slug)}
  end

  # Subscriptions

  def all_subscriptions(%{streamer_username: streamer_username}, _) do
    streamer = Accounts.get_by_username(streamer_username)

    {:ok, Payments.list_streamer_subscribers(streamer)}
  end

  def all_subscriptions(%{user_username: user_username}, _) do
    user = Accounts.get_by_username(user_username)

    {:ok, Payments.list_user_subscriptions(user)}
  end

  def all_subscriptions(%{streamer_username: streamer_username, user_username: user_username}, _) do
    user = Accounts.get_by_username(user_username)
    streamer = Accounts.get_by_username(streamer_username)

    {:ok, Payments.get_channel_subscription!(user, streamer)}
  end

  def all_subscriptions(_, _) do
    {:ok, Payments.list_all_subscriptions()}
  end

  # Followers

  def all_followers(%{streamer_username: streamer_username}, _) do
    streamer = Accounts.get_by_username(streamer_username)
    {:ok, Streams.list_followers(streamer)}
  end

  def all_followers(%{user_username: user_username}, _) do
    user = Accounts.get_by_username(user_username)
    {:ok, Streams.list_following(user)}
  end

  def all_followers(%{streamer_username: streamer_username, user_username: user_username}, _) do
    streamer = Accounts.get_by_username(streamer_username)
    user = Accounts.get_by_username(user_username)
    {:ok, Streams.get_following(streamer, user)}
  end

  def all_followers(_, _) do
    {:ok, Streams.list_all_follows()}
  end
end
