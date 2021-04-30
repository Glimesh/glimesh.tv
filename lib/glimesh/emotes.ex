defmodule Glimesh.Emotes do
  @moduledoc """
  Glimesh Custom Emote Handler
  """

  import Ecto.Query, warn: false
  alias Glimesh.Accounts.User
  alias Glimesh.Streams.Channel
  alias Glimesh.Emotes.Emote
  alias Glimesh.Repo

  defdelegate authorize(action, user, params), to: Glimesh.Emotes.Policy

  def list_emotes do
    Application.get_env(:glimesh, :emotes)
  end

  def list_animated_emotes do
    Application.get_env(:glimesh, :animated_emotes)
  end

  def list_emotes_for_js(include_animated \\ false) do
    list_emotes_by_key_and_image(include_animated)
    |> Enum.map(fn {name, img} ->
      %{name: name, emoji: GlimeshWeb.Router.Helpers.static_url(GlimeshWeb.Endpoint, img)}
    end)
    |> Jason.encode!()
  end

  def list_emotes_by_key_and_image(include_animated \\ false) do
    regular =
      list_emotes()
      |> Enum.into(%{}, fn {name, images} -> {name, Map.get(images, :svg)} end)

    animated =
      if include_animated do
        list_animated_emotes()
        |> Enum.into(%{}, fn {name, images} -> {name, Map.get(images, :gif)} end)
      else
        %{}
      end

    Map.merge(regular, animated)
  end

  def list_emote_identifiers do
    list_emotes()
    |> Map.keys()
  end

  def get_svg_by_identifier(id) do
    list_emotes()
    |> get_in([id, :svg])
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
end
