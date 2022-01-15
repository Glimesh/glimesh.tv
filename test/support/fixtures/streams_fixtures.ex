defmodule Glimesh.StreamsFixtures do
  @moduledoc """
    Test helpers for the Glimesh.Streams functions
  """

  def channel_banned_user_fixture(
        %Glimesh.Streams.Channel{} = channel,
        %Glimesh.Accounts.User{} = banned_user
      ) do
    {:ok, channel_ban} =
      %Glimesh.Streams.ChannelBan{channel: channel, user: banned_user}
      |> Glimesh.Streams.ChannelBan.changeset(%{expires_at: nil})
      |> Glimesh.Repo.insert()

    channel_ban
  end

  def channel_timed_out_user_fixture(
        %Glimesh.Streams.Channel{} = channel,
        %Glimesh.Accounts.User{} = banned_user,
        until
      ) do
    {:ok, channel_ban} =
      %Glimesh.Streams.ChannelBan{channel: channel, user: banned_user}
      |> Glimesh.Streams.ChannelBan.changeset(%{expires_at: until})
      |> Glimesh.Repo.insert()

    channel_ban
  end

  def change_channel_status(%Glimesh.Streams.Channel{} = channel, status) do
    Glimesh.Streams.change_channel(channel, %{status: status})
    |> Glimesh.Repo.update()
  end
end
