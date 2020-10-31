defmodule Glimesh.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glimesh.Accounts` context.
  """

  def unique_user_username, do: "user#{System.unique_integer([:positive])}"
  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def streamer_fixture(attrs \\ %{}) do
    streamer = user_fixture(attrs)
    {:ok, _} = Glimesh.Streams.create_channel(streamer)

    streamer
  end

  def channel_fixture(attrs \\ %{}) do
    streamer = user_fixture(attrs)
    {:ok, channel} = Glimesh.Streams.create_channel(streamer)

    channel
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> Enum.into(%{
        username: unique_user_username(),
        email: unique_user_email(),
        password: valid_user_password()
      })
      |> Glimesh.Accounts.register_user()

    user
  end

  def admin_fixture(_attrs \\ %{}) do
    user_fixture(%{is_admin: true})
  end

  def banned_fixture(_attrs \\ %{}) do
    user_fixture(%{is_banned: true})
  end

  def extract_user_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end
end
