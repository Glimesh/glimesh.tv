defmodule Glimesh.ChannelLookups do
  @moduledoc """
  Channel Filtering Functionality
  """

  import Ecto.Query, warn: false

  alias Glimesh.AccountFollows.Follower
  alias Glimesh.Accounts.User
  alias Glimesh.Repo
  alias Glimesh.Streams.{Category, Channel, ChannelHosts}

  ## Filtering
  @spec search_live_channels(map) :: list
  def search_live_channels(params) do
    Channel
    |> where([c], c.status == "live")
    |> apply_filter(:ids, params)
    |> apply_filter(:category, params)
    |> apply_filter(:subcategory, params)
    |> apply_filter(:tags, params)
    |> apply_filter(:language, params)
    |> order_by(fragment("RANDOM()"))
    |> group_by([c], c.id)
    |> preload([:category, :subcategory, :user, :stream, :tags])
    |> Repo.all()
  end

  defp apply_filter(query, :category, %{"ids" => ids}) when is_list(ids) do
    where(query, [c], c.id in ^ids)
  end

  defp apply_filter(query, :category, %{"category" => category_slug})
       when is_binary(category_slug) do
    category = Glimesh.ChannelCategories.get_category(category_slug)

    where(query, [c], c.category_id == ^category.id)
  end

  defp apply_filter(query, :subcategory, %{
         "category" => category_slug,
         "subcategory" => subcategories
       })
       when is_binary(category_slug) and is_list(subcategories) do
    category = Glimesh.ChannelCategories.get_category(category_slug)

    query
    |> join(:inner, [c], assoc(c, :subcategory), as: :subcategory)
    |> where([subcategory: sc], sc.category_id == ^category.id)
    |> where([subcategory: sc], sc.slug in ^subcategories)
  end

  defp apply_filter(query, :tags, %{"tags" => tags}) when is_list(tags) do
    query
    |> join(:inner, [c], assoc(c, :tags), as: :tags)
    |> where([tags: t], t.slug in ^tags)
  end

  defp apply_filter(query, :language, %{"language" => language}) when is_binary(language) do
    where(query, [c], c.language == ^language)
  end

  defp apply_filter(query, :language, %{"language" => languages}) when is_list(languages) do
    where(query, [c], c.language in ^languages)
  end

  defp apply_filter(query, _field, _params) do
    query
  end

  def count_live_channels(%Category{id: category_id}) do
    Repo.one(
      from c in Channel,
        select: count(c.id),
        where: c.status == "live" and c.category_id == ^category_id
    )
  end

  def list_channels(wheres \\ []), do: Repo.all(query_channels(wheres))

  def query_channels(wheres \\ []) do
    from c in Channel,
      join: cat in Category,
      on: cat.id == c.category_id,
      where: ^wheres,
      preload: [:category, :user]
  end

  def list_live_channels do
    search_live_channels(%{})
  end

  def list_live_subscribed_followers(%Channel{} = channel) do
    Repo.all(
      from u in User,
        left_join: f in Follower,
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
        join: f in Follower,
        on: c.user_id == f.streamer_id,
        where: c.status == "live",
        where: f.user_id == ^user.id
    )
    |> Repo.preload([:category, :user, :stream, :subcategory, :tags])
  end

  def count_live_followed_channels_that_are_hosting(%User{} = user) do
    from(c in Channel,
      left_join: f in Follower,
      on: c.user_id == f.streamer_id,
      join: ch in ChannelHosts,
      on: c.id == ch.hosting_channel_id,
      join: target in Channel,
      on: target.id == ch.target_channel_id,
      where: ch.status == "hosting",
      where: target.status == "live",
      where: f.user_id == ^user.id,
      where:
        fragment(
          "not exists(select true from followers where user_id = ? and streamer_id = ?)",
          ^user.id,
          target.user_id
        ),
      distinct: target.id,
      select: [target]
    )
    |> Repo.all()
    |> length()
  end

  def list_live_followed_channels_and_hosts(%User{} = user) do
    include_hosts_query =
      from(c in Channel,
        left_join: f in Follower,
        on: c.user_id == f.streamer_id,
        join: ch in ChannelHosts,
        on: c.id == ch.hosting_channel_id,
        join: target in Channel,
        on: target.id == ch.target_channel_id,
        where: ch.status == "hosting",
        where: target.status == "live",
        where: f.user_id == ^user.id,
        where:
          fragment(
            "not exists(select true from followers where user_id = ? and streamer_id = ?)",
            ^user.id,
            target.user_id
          ),
        distinct: target.id,
        select: [target],
        select_merge: %{match_type: "hosting"}
      )

    live_followed_query =
      from([c] in Channel,
        join: f in Follower,
        on: c.user_id == f.streamer_id,
        where: c.status == "live",
        where: f.user_id == ^user.id,
        select_merge: %{match_type: "live"}
      )

    query = live_followed_query |> union_all(^include_hosts_query)

    Repo.all(query)
    |> Repo.preload([:user, :category, :stream, :subcategory, :tags])
  end

  def list_all_followed_channels(user) do
    Repo.all(
      from c in Channel,
        join: f in Follower,
        on: c.user_id == f.streamer_id,
        where: f.user_id == ^user.id
    )
    |> Repo.preload([:category, :user, :stream])
  end

  def list_followed_live_notification_channels(user) do
    Repo.all(
      from c in Channel,
        join: f in Follower,
        on: c.user_id == f.streamer_id,
        where: f.user_id == ^user.id and f.has_live_notifications == true
    )
    |> Repo.preload([:category, :user, :streamer])
  end

  def get(id, preloads \\ []) do
    Channel |> preload(^preloads) |> Repo.get(id)
  end

  def get_channel(id) do
    Repo.get_by(Channel, id: id) |> Repo.preload([:category, :subcategory, :user, :tags])
  end

  def get_channel!(id) do
    Repo.get_by!(Channel, id: id) |> Repo.preload([:category, :subcategory, :user, :tags])
  end

  def get_channel_for_username(username, ignore_banned \\ false) do
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
    |> Repo.preload([:category, :stream, :subcategory, :user, :tags])
  end

  def get_channel_for_user_id(user_id, ignore_banned \\ false) do
    query =
      Channel
      |> join(:inner, [u], assoc(u, :user), as: :user)
      |> where([user: u], u.id == ^user_id)
      |> where([c], c.inaccessible == false)

    query =
      if ignore_banned do
        query
      else
        where(query, [user: u], u.is_banned == false)
      end

    Repo.one(query)
    |> Repo.preload([:category, :stream, :subcategory, :user, :tags])
  end

  def get_channel_by_hmac_key(hmac_key) do
    Repo.one(
      from c in Channel,
        where: c.hmac_key == ^hmac_key and c.inaccessible == false
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

  @doc """
  Get any channel for a user, even if it is deactivated
  """
  def get_any_channel_for_user(user) do
    Repo.one(from c in Channel, where: c.user_id == ^user.id)
  end

  def search_hostable_channels_by_name(hosting_user, target_name) do
    if target_name != nil and String.length(target_name) < 25 do
      search_term = Regex.replace(~r/(\\\\|_|%)/, target_name, "\\\\\\1") <> "%"

      hosting_channel = Glimesh.ChannelLookups.get_channel_for_user_id(hosting_user.id)

      Repo.all(
        from c in Channel,
          join: u in User,
          on: c.user_id == u.id,
          where: ilike(u.displayname, ^search_term),
          where: c.allow_hosting == true,
          where: c.inaccessible == false,
          where: c.user_id != ^hosting_user.id,
          where: u.is_banned == false,
          where: u.can_stream == true,
          where:
            fragment(
              "not exists(select user_id from channel_bans where user_id = ? and channel_id = ? and expires_at is null)",
              ^hosting_user.id,
              c.id
            ),
          where:
            fragment(
              "not exists(select target_channel_id from channel_hosts where target_channel_id = ? and hosting_channel_id = ?)",
              c.id,
              ^hosting_channel.id
            ),
          order_by: [asc: u.displayname],
          limit: 10
      )
      |> Repo.preload([:user])
    else
      []
    end
  end
end
