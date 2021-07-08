defmodule Glimesh.Emotes.Policy do
  @moduledoc """
  Glimesh Emotes Policy

  :create_global_emote -> Should allow admins or GCT to upload
  :create_emote -> Should allow admins, GCT, or the Channel Owner to upload
  """

  @behaviour Bodyguard.Policy

  alias Glimesh.Accounts.User
  alias Glimesh.Emotes.Emote
  alias Glimesh.Streams.Channel

  def authorize(:create_global_emote, %User{is_admin: true}, _), do: true
  def authorize(:create_global_emote, %User{is_gct: true, gct_level: 5}, _), do: true
  def authorize(:create_global_emote, %User{is_gct: true, gct_level: 4}, _), do: true

  def authorize(:create_channel_emote, %User{is_admin: true}, _channel), do: true
  def authorize(:create_channel_emote, %User{is_gct: true, gct_level: 5}, _), do: true
  def authorize(:create_channel_emote, %User{is_gct: true, gct_level: 4}, _), do: true

  def authorize(:create_channel_emote, %User{id: user_id}, %Channel{user_id: channel_user_id}),
    do: user_id == channel_user_id

  def authorize(:delete_emote, %User{id: user_id}, %Emote{} = emote) do
    emote = emote |> Glimesh.Repo.preload(:channel)

    emote.channel.user_id == user_id
  end

  def authorize(_, _, _), do: false
end
