defmodule Glimesh.StreamModeration do
  @moduledoc """
  The Streams Moderation Context.
  """
  import Ecto.Query, warn: false
  alias Glimesh.Repo

  alias Glimesh.Accounts.User
  alias Glimesh.Streams.Channel
  alias Glimesh.Streams.ChannelBan
  alias Glimesh.Streams.ChannelModerationLog
  alias Glimesh.Streams.ChannelModerator

  defdelegate authorize(action, user, params), to: Glimesh.Streams.Policy

  # User API Calls
  def get_channel_moderator!(%User{} = user, id) do
    chan_mod = Repo.get!(ChannelModerator, id) |> Repo.preload([:channel, :user])

    with :ok <- Bodyguard.permit(__MODULE__, :show_channel_moderator, user, chan_mod.channel) do
      chan_mod
    end
  end

  def get_channel_moderator(%User{} = user, id) do
    chan_mod = Repo.get(ChannelModerator, id) |> Repo.preload([:channel, :user])

    if chan_mod do
      with :ok <- Bodyguard.permit(__MODULE__, :show_channel_moderator, user, chan_mod.channel) do
        {:ok, chan_mod}
      end
    else
      # If the record has been deleted, fake the error from Bodyguard
      {:error, :unauthorized}
    end
  end

  def list_channel_moderators(%User{} = user, %Channel{} = channel) do
    with :ok <- Bodyguard.permit(__MODULE__, :show_channel_moderator, user, channel) do
      Repo.all(from cm in ChannelModerator, where: cm.channel_id == ^channel.id)
      |> Repo.preload([:user])
    end
  end

  def list_channel_moderation_log(%User{} = user, %Channel{} = channel) do
    with :ok <- Bodyguard.permit(__MODULE__, :show_channel_moderator, user, channel) do
      Repo.all(
        from ml in ChannelModerationLog,
          where: ml.channel_id == ^channel.id,
          order_by: [desc: :inserted_at]
      )
      |> Repo.preload([:moderator, :user])
    end
  end

  def list_channel_moderation_log_for_mod(%User{} = user, %ChannelModerator{} = chan_mod) do
    with :ok <- Bodyguard.permit(__MODULE__, :show_channel_moderator, user, chan_mod.channel) do
      Repo.all(
        from ml in ChannelModerationLog,
          where: ml.channel_id == ^chan_mod.channel_id and ml.moderator_id == ^chan_mod.user_id,
          order_by: [desc: :inserted_at]
      )
      |> Repo.preload([:user])
    end
  end

  def list_channel_bans(%User{} = user, %Channel{} = channel) do
    with :ok <- Bodyguard.permit(__MODULE__, :show_channel_moderator, user, channel) do
      Repo.all(
        from cb in ChannelBan,
          where: cb.channel_id == ^channel.id and is_nil(cb.expires_at),
          order_by: [desc: :inserted_at]
      )
      |> Repo.preload([:user])
    end
  end

  def create_channel_moderator(user, channel, new_moderator, attrs \\ %{})

  def create_channel_moderator(
        %User{} = user,
        %Channel{} = channel,
        %User{} = new_moderator,
        attrs
      ) do
    with :ok <- Bodyguard.permit(__MODULE__, :create_channel_moderator, user, channel) do
      %ChannelModerator{
        channel: channel,
        user: new_moderator
      }
      |> ChannelModerator.changeset(attrs)
      |> Repo.insert()
    end
  end

  def create_channel_moderator(
        %User{id: user_id},
        %Channel{user_id: channel_user_id} = channel,
        new_moderator,
        attrs
      )
      when is_nil(new_moderator)
      when user_id == channel_user_id do
    change =
      %ChannelModerator{
        channel: channel,
        user: new_moderator
      }
      |> ChannelModerator.changeset(attrs)

    {:error_no_user, change}
  end

  def update_channel_moderator(%User{} = user, %ChannelModerator{} = chan_mod, attrs \\ %{}) do
    with :ok <- Bodyguard.permit(__MODULE__, :update_channel_moderator, user, chan_mod.channel) do
      chan_mod
      |> ChannelModerator.changeset(attrs)
      |> Repo.update()
    end
  end

  def delete_channel_moderator(%User{} = user, %ChannelModerator{} = chan_mod) do
    with :ok <- Bodyguard.permit(__MODULE__, :delete_channel_moderator, user, chan_mod.channel) do
      Repo.delete(chan_mod)
    end
  end

  # System API Calls

  def change_channel_moderator(%ChannelModerator{} = mod, attrs \\ %{}) do
    ChannelModerator.changeset(mod, attrs)
  end

  # Private Calls
end
