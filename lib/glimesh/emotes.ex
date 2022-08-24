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
    |> convert_for_json()
  end

  def convert_for_json(emotes) do
    emotes
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

  def list_emotes_for_parser(include_animated \\ false, channel_id \\ nil) do
    Emote
    |> where([e], is_nil(e.approved_at) == false)
    |> perform_emote_query(%{include_animated: include_animated, channel_id: channel_id})
    |> Repo.replica().all()
  end

  defp perform_emote_query(query, %{include_animated: false, channel_id: nil}) do
    query
    |> where([e], e.animated == false and is_nil(e.channel_id))
  end

  defp perform_emote_query(query, %{include_animated: true, channel_id: nil}) do
    query
    |> where([e], is_nil(e.channel_id))
  end

  defp perform_emote_query(query, %{include_animated: false, channel_id: channel_id}) do
    # Non platform sub, but should still get channel animated emotes
    query
    |> where([e], (e.animated == false and is_nil(e.channel_id)) or e.channel_id == ^channel_id)
  end

  defp perform_emote_query(query, %{include_animated: true, channel_id: channel_id}) do
    # Platform sub, should get all emotes
    query
    |> where([e], is_nil(e.channel_id) or e.channel_id == ^channel_id)
  end

  def list_static_emotes do
    Repo.replica().all(
      from(e in Emote,
        where: is_nil(e.channel_id) and is_nil(e.approved_at) == false and e.animated == false,
        order_by: e.emote
      )
    )
  end

  def list_animated_emotes do
    Repo.replica().all(
      from(e in Emote,
        where: is_nil(e.channel_id) and is_nil(e.approved_at) == false and e.animated == true,
        order_by: e.emote
      )
    )
  end

  def list_pending_emotes do
    Repo.replica().all(
      from(e in Emote,
        where: is_nil(e.approved_at) and is_nil(e.rejected_at),
        order_by: e.inserted_at
      )
    )
    |> Repo.preload(channel: [:user])
  end

  def count_all_emotes_for_channel(%Channel{id: channel_id}) do
    Repo.one!(
      from(e in Emote,
        select: count(e.id),
        where: e.channel_id == ^channel_id
      )
    )
  end

  def list_emotes_for_channel(%Channel{id: channel_id}) do
    Repo.replica().all(
      from(e in Emote,
        where: is_nil(e.approved_at) == false and e.channel_id == ^channel_id,
        order_by: e.emote
      )
    )
  end

  def list_static_emotes_for_channel(%Channel{id: channel_id}) do
    Repo.replica().all(
      from(e in Emote,
        where:
          is_nil(e.approved_at) == false and e.animated == false and e.channel_id == ^channel_id,
        order_by: e.emote
      )
    )
  end

  def list_animated_emotes_for_channel(%Channel{id: channel_id}) do
    Repo.replica().all(
      from(e in Emote,
        where:
          is_nil(e.approved_at) == false and e.animated == true and e.channel_id == ^channel_id,
        order_by: e.emote
      )
    )
  end

  def list_submitted_emotes_for_channel(%Channel{id: channel_id}) do
    Repo.replica().all(
      from(e in Emote,
        where: is_nil(e.approved_at) and e.channel_id == ^channel_id,
        order_by: [desc: e.rejected_at]
      )
    )
  end

  def get_emote_by_id(id) do
    Repo.replica().get_by(Emote, id: id)
  end

  def get_emote_by_emote(emote) when is_binary(emote) do
    Repo.replica().get_by(Emote, emote: emote)
  end

  def create_global_emote(%User{} = user, attrs \\ %{}) do
    with :ok <- Bodyguard.permit(__MODULE__, :create_global_emote, user) do
      %Emote{svg: true}
      |> Emote.changeset(attrs)
      |> Repo.insert()
    end
  end

  def create_channel_emote(%User{} = user, %Channel{} = channel, attrs \\ %{}) do
    with :ok <- Bodyguard.permit(__MODULE__, :create_channel_emote, user, channel) do
      %Emote{
        channel: channel,
        svg: false
      }
      |> Emote.channel_changeset(channel, attrs)
      |> Repo.insert()
    end
  end

  def delete_emote(%User{} = user, %Emote{} = emote) do
    with :ok <- Bodyguard.permit(__MODULE__, :delete_emote, user, emote) do
      emote
      |> Repo.delete()
    end
  end

  def approve_emote(%User{} = user, %Emote{} = emote) do
    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam.Policy, :manage_emotes, user) do
      emote
      |> Repo.preload(:reviewed_by)
      |> Emote.review_changeset(user, %{
        approved_at: NaiveDateTime.utc_now()
      })
      |> Repo.update()
    end
  end

  def reject_emote(%User{} = user, %Emote{} = emote, reason) do
    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam.Policy, :manage_emotes, user) do
      emote
      |> Repo.preload(:reviewed_by)
      |> Emote.review_changeset(user, %{
        rejected_at: NaiveDateTime.utc_now(),
        rejected_reason: reason
      })
      |> Repo.update()
    end
  end

  def full_url(%Emote{animated: true} = emote) do
    Glimesh.Uploaders.AnimatedEmote.url({emote.animated_file, emote}, :gif)
  end

  def full_url(%Emote{svg: true} = emote) do
    Glimesh.Uploaders.StaticEmote.url({emote.static_file, emote}, :svg)
  end

  def full_url(%Emote{} = emote) do
    Glimesh.Uploaders.StaticEmote.url({emote.static_file, emote}, :png)
  end
end
