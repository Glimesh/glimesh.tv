defmodule Glimesh.ChannelLookups do
  @moduledoc """
  Channel Filtering Functionality
  """

  import Ecto.Query, warn: false

  alias Glimesh.Accounts.User
  alias Glimesh.Repo
  alias Glimesh.Streams.Category
  alias Glimesh.Streams.Channel
  alias Glimesh.Streams.Followers
  alias Glimesh.Streams.Tag
  alias Glimesh.Streams.Category

  ## Filtering

  def list_channels do
    Repo.all(
      from c in Channel,
        join: cat in Category,
        on: cat.id == c.category_id
    )
    |> Repo.preload([:category, :user])
  end

  def list_live_channels do
    filter_live_channels()
  end

  def filter_live_channels(params \\ %{}) do
    Repo.all(perform_filter_live_channels(params))
    |> Repo.preload([:category, :user, :stream, :tags])
  end

  defp perform_filter_live_channels(%{"category" => _category_slug, "tag" => tag_slug}) do
    from c in Channel,
      join: t in Tag,
      join: ct in "channel_tags",
      on: ct.tag_id == t.id and ct.channel_id == c.id,
      where: c.status == "live" and t.slug == ^tag_slug
  end

  defp perform_filter_live_channels(%{"category" => category_slug}) do
    from c in Channel,
      join: cat in Category,
      on: cat.id == c.category_id,
      where: c.status == "live",
      where: cat.slug == ^category_slug
  end

  defp perform_filter_live_channels(params) when params == %{} do
    from c in Channel,
      where: c.status == "live"
  end

  def list_live_subscribed_followers(%Channel{} = channel) do
    Repo.all(
      from u in User,
        left_join: f in Followers,
        on: u.id == f.user_id,
        where:
          f.streamer_id == ^channel.user_id and
            f.has_live_notifications == true and
            u.allow_live_subscription_emails == true
    )
  end

  def list_live_followed_channels(user) do
    Repo.all(
      from c in Channel,
        join: f in Followers,
        on: c.user_id == f.streamer_id,
        where: c.status == "live",
        where: f.user_id == ^user.id
    )
    |> Repo.preload([:category, :user, :stream, :tags])
  end

  def list_all_followed_channels(user) do
    Repo.all(
      from c in Channel,
        join: f in Followers,
        on: c.user_id == f.streamer_id,
        where: f.user_id == ^user.id
    )
    |> Repo.preload([:category, :user, :stream])
  end

  def list_followed_live_notification_channels(user) do
    Repo.all(
      from c in Channel,
        join: f in Followers,
        on: c.user_id == f.streamer_id,
        where: f.user_id == ^user.id and f.has_live_notifications == true
    )
    |> Repo.preload([:category, :user, :streamer])
  end

  def get_channel(id) do
    Repo.get_by(Channel, id: id) |> Repo.preload([:category, :user, :tags])
  end

  def get_channel!(id) do
    Repo.get_by!(Channel, id: id) |> Repo.preload([:category, :user, :tags])
  end

  def get_channel_for_username!(username, ignore_banned \\ false) do
    query =
      Channel
      |> join(:inner, [u], assoc(u, :user), as: :user)
      |> where([user: u], u.username == ^username)
      |> where([c], c.inaccessible == false)

    query =
      if ignore_banned do
        query
      else
        where(query, [user: u], u.is_banned == false)
      end

    Repo.one(query)
    |> Repo.preload([:category, :user, :tags])
  end

  def get_channel_for_stream_key!(stream_key) do
    Repo.one(
      from c in Channel,
        where: c.stream_key == ^stream_key and c.inaccessible == false
    )
    |> Repo.preload([:category, :user])
  end

  def get_channel_for_user(user) do
    Repo.one(
      from c in Channel,
        join: u in User,
        on: c.user_id == u.id,
        where: u.id == ^user.id,
        where: c.inaccessible == false
    )
    |> Repo.preload([:category, :user])
  end
end
