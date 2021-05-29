defmodule Glimesh.Emotes do
  @moduledoc """
  Glimesh Custom Emote Handler
  """

  import Ecto.Query, warn: false
  alias Glimesh.Accounts.User
  alias Glimesh.Emotes.Emote
  alias Glimesh.Repo
  alias Glimesh.Streams.Channel

  defdelegate authorize(action, user, params), to: Glimesh.Emotes.Policy

  def list_emotes_for_js(include_animated \\ false) do
    list_emotes(include_animated)
    |> Enum.map(fn emote ->
      url = Glimesh.Emotes.full_url(emote)

      %{
        name: ":#{emote.emote}:",
        emoji: url
      }
    end)
    |> Jason.encode!()
  end

  def list_emotes(true) do
    list_static_emotes() ++ list_animated_emotes()
  end

  def list_emotes(false) do
    list_static_emotes()
  end

  def list_static_emotes do
    Repo.all(from(e in Emote, where: e.animated == false, order_by: e.emote))
  end

  def list_animated_emotes do
    Repo.all(from(e in Emote, where: e.animated == true, order_by: e.emote))
  end

  def list_static_emotes_for_channel(%Channel{id: channel_id}) do
    Repo.all(
      from(e in Emote,
        where: e.animated == false and e.channel_id == ^channel_id,
        order_by: e.emote
      )
    )
  end

  def list_animated_emotes_for_channel(%Channel{id: channel_id}) do
    Repo.all(
      from(e in Emote,
        where: e.animated == true and e.channel_id == ^channel_id,
        order_by: e.emote
      )
    )
  end

  def create_global_emote(%User{} = user, attrs \\ %{}) do
    with :ok <- Bodyguard.permit(__MODULE__, :create_global_emote, user) do
      %Emote{}
      |> Emote.changeset(attrs)
      |> Repo.insert()
    end
  end

  def create_channel_emote(%User{} = user, %Channel{} = channel, attrs \\ %{}) do
    with :ok <- Bodyguard.permit(__MODULE__, :create_channel_emote, user, channel) do
      %Emote{
        channel: channel
      }
      |> Emote.channel_changeset(channel.emote_prefix, attrs)
      |> Repo.insert()
    end
  end

  def full_url(%Emote{animated: true} = emote) do
    Glimesh.Uploaders.AnimatedEmote.url({emote.animated_file, emote}, :gif)
  end

  def full_url(%Emote{} = emote) do
    Glimesh.Uploaders.StaticEmote.url({emote.static_file, emote}, :svg)
  end
end
