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
    |> Jason.encode!()
  end

  def list_emotes(include_animated \\ false) do
    list_emotes_by_key_and_image(include_animated)
    |> Enum.map(fn emote ->
      url = Glimesh.Emotes.full_url(emote)

      %{
        name: ":#{emote.emote}:",
        emoji: url
      }
    end)
  end

  def list_emotes_by_key_and_image(true) do
    list_static_emotes() ++ list_animated_emotes()
  end

  def list_emotes_by_key_and_image(false) do
    list_static_emotes()
  end

  def list_all_emotes do
    Repo.all(Emote)
  end

  def list_static_emotes do
    Repo.all(from e in Emote, where: e.animated == false)
  end

  def list_animated_emotes do
    Repo.all(from e in Emote, where: e.animated == true)
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
      |> Emote.changeset(attrs)
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
