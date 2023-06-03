defmodule Glimesh.Emotes do
  @moduledoc """
  Glimesh Custom Emote Handler
  """

  import Ecto.Query, warn: false
  alias Glimesh.Accounts.User
  alias Glimesh.Emotes.Emote
  alias Glimesh.Payments.Subscription
  alias Glimesh.Repo
  alias Glimesh.Streams.Channel

  defdelegate authorize(action, user, params), to: Glimesh.Emotes.Policy

  def list_emotes_for_js(include_animated \\ false, userid) do
    list_emotes(include_animated, userid)
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

  def list_emotes(true, userid) do
    list_static_emotes(userid) ++ list_glimesh_animated_emotes()
  end

  def list_emotes(false, userid) do
    list_static_emotes(userid)
  end

  def list_emotes_gct do
    Repo.replica().all(
      from(e in Emote,
        left_join: c in Channel,
        on: c.id == e.channel_id,
        where:
          is_nil(e.approved_at) == false and
            (is_nil(e.channel_id) or
               (is_nil(e.channel_id) == false and e.approved_for_global_use == true and
                  e.allow_global_usage == true and e.emote_display_off == false)),
        order_by: e.emote
      )
    )
  end

  def list_emotes_for_parser(include_animated \\ false, channel_id \\ nil, userid) do
    Emote
    |> join(:left, [e], c in Channel, on: c.id == e.channel_id)
    |> join(:left, [e, c], s in Subscription,
      on: s.user_id == ^userid and s.streamer_id == c.user_id
    )
    |> where([e], is_nil(e.approved_at) == false)
    |> perform_emote_query(%{include_animated: include_animated, channel_id: channel_id}, userid)
    |> Repo.replica().all()
  end

  defp perform_emote_query(query, %{include_animated: false, channel_id: nil}, _userid) do
    query
    |> where([e], e.animated == false and is_nil(e.channel_id) and e.emote_display_off == false)
  end

  defp perform_emote_query(query, %{include_animated: true, channel_id: nil}, _userid) do
    query
    |> where([e], is_nil(e.channel_id) and e.emote_display_off == false)
  end

  # credo:disable-for-lines:14
  defp perform_emote_query(query, %{include_animated: false, channel_id: channel_id}, userid) do
    # Non platform sub, but should still get channel animated emotes
    query
    |> where(
      [e, c, s],
      (e.animated == false and is_nil(e.channel_id) and e.emote_display_off == false) or
        (e.emote_display_off == false and
           (e.channel_id == ^channel_id or
              (is_nil(e.channel_id) == false and e.approved_for_global_use == true and
                 e.allow_global_usage == true)) and
           (e.require_channel_sub == false or
              (e.require_channel_sub == true and (s.is_active == true or c.user_id == ^userid))))
    )
  end

  # credo:disable-for-lines:14
  defp perform_emote_query(query, %{include_animated: true, channel_id: channel_id}, userid) do
    # Platform sub, should get all emotes
    query
    |> where(
      [e, c, s],
      (is_nil(e.channel_id) and e.emote_display_off == false) or
        (e.emote_display_off == false and
           (e.channel_id == ^channel_id or
              (is_nil(e.channel_id) == false and e.approved_for_global_use == true and
                 e.allow_global_usage == true)) and
           (e.require_channel_sub == false or
              (e.require_channel_sub == true and (s.is_active == true or c.user_id == ^userid))))
    )
  end

  # credo:disable-for-lines:23
  def list_static_emotes(userid) do
    # Allow use of all emotes except for Glimesh animated (Platform Sub)
    Repo.replica().all(
      from(e in Emote,
        left_join: c in Channel,
        on: c.id == e.channel_id,
        left_join: s in Subscription,
        on: s.user_id == ^userid and s.streamer_id == c.user_id,
        where:
          is_nil(e.approved_at) == false and e.emote_display_off == false and
            ((e.animated == false and is_nil(e.channel_id)) or
               (is_nil(e.channel_id) == false and e.approved_for_global_use == true and
                  e.allow_global_usage == true and
                  (e.require_channel_sub == false or
                     (e.require_channel_sub == true and
                        (s.is_active == true or c.user_id == ^userid))))),
        distinct: e.id,
        order_by: e.emote
      )
    )
  end

  def list_glimesh_animated_emotes do
    # List animated emotes with no channel for use with Platform sub
    Repo.replica().all(
      from(e in Emote,
        where:
          is_nil(e.approved_at) == false and e.animated == true and is_nil(e.channel_id) and
            e.emote_display_off == false,
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

  # credo:disable-for-lines:19
  def list_emotes_for_channel(%Channel{id: channel_id}, userid) do
    # Modified to ignore the channel :D
    Repo.replica().all(
      from(e in Emote,
        left_join: c in Channel,
        on: c.id == e.channel_id,
        left_join: s in Subscription,
        on: s.user_id == ^userid and s.streamer_id == c.user_id,
        where:
          is_nil(e.approved_at) == false and
            e.emote_display_off == false,
        distinct: e.id,
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

  def save_emote_options(%User{} = user, %Emote{} = emote, attrs \\ %{}) do
    with :ok <- Bodyguard.permit(__MODULE__, :save_emote_options, user, emote) do
      emote
      |> Emote.preference_changeset(attrs)
      |> Repo.update()
    end
  end

  def clear_global_emotes(%User{} = user, %Emote{} = emote) do
    oldemote =
      Repo.replica().one(
        from(e in Emote,
          left_join: c in Channel,
          on: c.id == e.channel_id,
          where: c.user_id == ^user.id and e.allow_global_usage == true and e.id != ^emote.id
        )
      )

    if not is_nil(oldemote) do
      oldemote
      |> Emote.preference_changeset(%{allow_global_usage: false})
      |> Repo.update()
    end
  end

  def save_gct_emote_options(%User{} = user, %Emote{} = emote, attrs \\ %{}) do
    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam.Policy, :disable_global_emotes, user) do
      if is_nil(emote.channel_id) or attrs["emote_display_off"] == "false" do
        emote
        |> Emote.preference_changeset(attrs)
        |> Repo.update()
      else
        emote
        |> Repo.preload(:reviewed_by)
        |> Emote.review_changeset(user, %{
          approved_at: NaiveDateTime.utc_now(),
          approved_for_global_use: false,
          rejected_reason:
            "#{emote.emote} is unable to be used platform wide. Please reach out to support@glimesh.tv for more information"
        })
        |> Repo.update()
      end
    end
  end

  def approve_emote(%User{} = user, %Emote{} = emote) do
    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam.Policy, :manage_emotes, user) do
      emote
      |> Repo.preload(:reviewed_by)
      |> Emote.review_changeset(user, %{
        approved_at: NaiveDateTime.utc_now(),
        approved_for_global_use: true
      })
      |> Repo.update()
    end
  end

  def approve_emote_sub_only(%User{} = user, %Emote{} = emote, reason) do
    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam.Policy, :manage_emotes, user) do
      emote
      |> Repo.preload(:reviewed_by)
      |> Emote.review_changeset(user, %{
        approved_at: NaiveDateTime.utc_now(),
        approved_for_global_use: false,
        rejected_reason: reason
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

  def file_type(%Emote{animated: true} = emote), do: :gif

  def file_type(%Emote{svg: true} = emote), do: :svg

  def file_type(%Emote{} = emote), do: :png
end
