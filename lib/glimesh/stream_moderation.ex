defmodule Glimesh.StreamModeration do
  @moduledoc """
  The Streams Moderation Context.
  """
  import Ecto.Query, warn: false

  alias Glimesh.Streams.Channel
  alias Glimesh.Streams.ChannelModerator
  alias Glimesh.Streams.ChannelModerationLog
  alias Glimesh.Streams.ChannelBan

  defdelegate authorize(action, user, params), to: Glimesh.Streams.Policy

  def list_channel_moderators(%Channel{} = channel) do
    Repo.all(from cm in ChannelModerator, where: cm.channel_id == ^channel.id)
    |> Repo.preload([:user])
  end

  def list_channel_moderation_log(%Channel{} = channel) do
    Repo.all(
      from ml in ChannelModerationLog,
        where: ml.channel_id == ^channel.id,
        order_by: [desc: :inserted_at]
    )
    |> Repo.preload([:moderator, :user])
  end

  def list_channel_moderation_log_for_mod(%ChannelModerator{} = chan_mod) do
    Repo.all(
      from ml in ChannelModerationLog,
        where: ml.channel_id == ^chan_mod.channel_id and ml.moderator_id == ^chan_mod.user_id,
        order_by: [desc: :inserted_at]
    )
    |> Repo.preload([:user])
  end

  def can_show_mod?(%User{} = user, %ChannelModerator{} = mod) do
    user.id == mod.channel.user_id
  end

  def can_edit_mod?(%User{} = user, %ChannelModerator{} = mod) do
    user.id == mod.channel.user_id
  end

  def list_channel_bans(%Channel{} = channel) do
    Repo.all(
      from cb in ChannelBan,
        where: cb.channel_id == ^channel.id and is_nil(cb.expires_at),
        order_by: [desc: :inserted_at]
    )
    |> Repo.preload([:user])
  end

  def get_channel_moderator!(id) do
    Repo.get!(ChannelModerator, id) |> Repo.preload([:channel, :user])
  end

  def create_channel_moderator(%Channel{} = channel, user, attrs \\ %{}) do
    change =
      %ChannelModerator{
        channel: channel,
        user: user
      }
      |> ChannelModerator.changeset(attrs)

    if is_nil(user) or channel.user_id == user.id do
      {:error_no_user, change}
    else
      change |> Repo.insert()
    end
  end

  def change_channel_moderator(%ChannelModerator{} = mod, attrs \\ %{}) do
    ChannelModerator.changeset(mod, attrs)
  end

  def update_channel_moderator(%ChannelModerator{} = mod, attrs \\ %{}) do
    mod
    |> ChannelModerator.changeset(attrs)
    |> Repo.update()
  end

  def delete_channel_moderator(%ChannelModerator{} = mod) do
    Repo.delete(mod)
  end
end
