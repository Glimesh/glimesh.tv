defmodule Glimesh.ChannelHostsLookups do
  @moduledoc """
  Channel Hosting lookups
  """

  import Ecto.Query, warn: false

  alias Glimesh.ChannelLookups
  alias Glimesh.Repo
  alias Glimesh.Streams.ChannelHosts

  def get_channel_hosting_list(channel_id) do
    ChannelHosts
    |> where([ch], ch.hosting_channel_id == ^channel_id)
    |> preload(host: [:user], target: [:user])
    |> Repo.replica().all()
  end

  def get_current_hosting_target(channel) do
    ChannelHosts
    |> where([ch], ch.hosting_channel_id == ^channel.id and ch.status == "hosting")
    |> limit(1)
    |> preload(host: [:user], target: [:user])
    |> Repo.one()
  end

  def get_targets_host_info(host_username, target_channel) do
    host = ChannelLookups.get_channel_for_username(host_username)

    ChannelHosts
    |> where(
      [ch],
      ch.hosting_channel_id == ^host.id and ch.status == "hosting" and
        ch.target_channel_id == ^target_channel.id
    )
    |> preload(host: [:user], target: [:user])
    |> Repo.one()
  end

  @doc """
   Used by Auto Host Job -- find channels that are being hosted but are no longer live and reset them to "ready" state
  """
  def unhost_channels_not_live do
    sql = """
      update channel_hosts\
      set status = 'ready'\
      where id in\
      (select ch.id from channel_hosts as ch\
       inner join channels as tc on ch.target_channel_id = tc.id\
       inner join channels as hc on ch.hosting_channel_id = hc.id\
       where (tc.status != 'live' or hc.status = 'live')\
       and ch.status = 'hosting')\
      returning id\
    """

    Repo.query(sql)
  end

  @doc """
   Used by Auto Host Job -- find channels that are no longer eligible for hosting by the current host and set them to "error" state
  """
  def invalidate_hosting_channels_where_necessary do
    sql = """
      update channel_hosts\
      set status = 'error'\
      where id in\
      (select ch.id from channel_hosts as ch\
       inner join channels as tc on ch.target_channel_id = tc.id\
       inner join users as tu on tc.user_id = tu.id\
       inner join channels as hc on ch.hosting_channel_id = hc.id\
       inner join users as hu on hc.user_id = hu.id\
       where ch.status != 'error'\
       and (tc.allow_hosting = 'false'\
       or tc.inaccessible = 'true'\
       or tu.is_banned = 'true'\
       or tu.can_stream = 'false'\
       or exists(select user_id from channel_bans where user_id = hc.user_id and channel_id = tc.id and expires_at is null)\
       or hu.is_banned = 'true'\
       or hu.can_stream = 'false'\
       or hc.inaccessible = 'true'))\
      returning id\
    """

    Repo.query(sql)
  end

  @doc """
   Used by Auto Host Job -- find channels that are live with hosted channels that aren't live and host them!
   This will only affect channel_hosts table records in "ready" state -- it is assumed that invalidate_hosting_channels_where_necessary()
   and unhost_channels_not_live() have updated the channel_hosts table record states appropriately.
  """
  def host_some_channels do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    sql = """
      update channel_hosts\
      set status = 'hosting', last_hosted_date = $1\
      where id in\
        (select distinct on(ch_sub.hosting_channel_id) ch_sub.id\
        from channel_hosts as ch_sub\
        inner join channels as tc on ch_sub.target_channel_id = tc.id\
        inner join channels as hc on ch_sub.hosting_channel_id = hc.id\
        where ch_sub.status = 'ready'\
        and hc.status = 'offline'\
        and tc.status = 'live'\
        and not exists(select true from channel_hosts where status = 'hosting' and hosting_channel_id = ch_sub.hosting_channel_id)\
        group by ch_sub.id\
        order by ch_sub.hosting_channel_id asc, min(coalesce(ch_sub.last_hosted_date, to_timestamp(0))) asc)\
      returning id\
    """

    Repo.query(sql, [now])
  end

  def recheck_error_status_channels do
    sql = """
      update channel_hosts\
      set status = 'ready'\
      where id in\
      (select ch.id from channel_hosts as ch\
       inner join channels as tc on ch.target_channel_id = tc.id\
       inner join users as tu on tc.user_id = tu.id\
       inner join channels as hc on ch.hosting_channel_id = hc.id\
       inner join users as hu on hc.user_id = hu.id\
       where ch.status = 'error'\
       and tc.allow_hosting = 'true'\
       and tc.inaccessible = 'false'\
       and tu.is_banned = 'false'\
       and tu.can_stream = 'true'\
       and not exists(select user_id from channel_bans where user_id = hc.user_id and channel_id = tc.id and expires_at is null)\
       and hu.is_banned = 'false'\
       and hu.can_stream = 'true'\
       and hc.inaccessible = 'false')\
      returning id\
    """

    Repo.query(sql)
  end
end
