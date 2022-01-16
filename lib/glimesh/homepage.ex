defmodule Glimesh.Homepage do
  @moduledoc """
  Responsible for preparing and updating the homepage.
  """

  import Ecto.Query, warn: false

  alias Ecto.Changeset
  alias Glimesh.Repo
  alias Glimesh.Streams.Channel
  alias Glimesh.Streams.HomepageChannel

  @doc """
  Gets the homepage channels.
  """
  def get_homepage do
    now = NaiveDateTime.utc_now()

    channel_ids =
      Repo.all(
        from f in HomepageChannel,
          select: f.channel_id,
          where:
            f.slot_started_at <= ^now and
              f.slot_ended_at >= ^now
      )

    # Fetch by ID's so we can be sure to use the models the UI needs
    Glimesh.ChannelLookups.search_live_channels(%{"ids" => channel_ids})
  end

  def list_homepage_channels do
    now = NaiveDateTime.utc_now()

    Repo.all(
      from f in HomepageChannel,
        select: f.channel_id,
        where:
          f.slot_started_at <= ^now and
            f.slot_ended_at >= ^now
    )
  end

  @doc """
  Update the homepage with new streams.

  Since our servers can be restarted at any time, this function needs to check for 15 minutes left on the current batch of streams, and prepare the next batch of streams. This function does not handle actually displaying the batch, which is where the homepage takes over.
  """
  @spec update_homepage :: :first_run | :late | :not_time | :on_time
  def update_homepage do
    # Check for the current max slot_ended_at time
    # If within 15 minutes of current time generate next batch of homepage channels
    slot_max_time = get_max_slot_time()
    now = NaiveDateTime.utc_now()

    cond do
      is_nil(slot_max_time) ->
        push_new_homepage_batch(now)
        :first_run

      NaiveDateTime.compare(now, slot_max_time) == :gt ->
        # If somehow we missed the 15 minute windo
        push_new_homepage_batch(now)
        :late

      NaiveDateTime.diff(slot_max_time, now) <= 15 * 60 ->
        # Create the next batch of channels, 54000
        push_new_homepage_batch(slot_max_time)
        :on_time

      true ->
        :not_time
    end
  end

  defp push_new_homepage_batch(max_last_slot_time) do
    start_time = max_last_slot_time
    end_time = NaiveDateTime.add(start_time, 60 * 60, :second)

    find_eligible_channels()
    |> Enum.each(fn channel ->
      create_homepage_channel!(channel, start_time, end_time)
    end)
  end

  defp find_eligible_channels do
    fifteen_minutes_ago = NaiveDateTime.add(NaiveDateTime.utc_now(), -(15 * 60), :second)

    ten_hour_query =
      from s in Glimesh.Streams.Stream,
        select: s.channel_id,
        group_by: s.channel_id,
        having: sum(s.ended_at - s.started_at) >= fragment("INTERVAL '10 hours'")

    Repo.all(
      from c in Channel,
        as: :channel,
        join: s in assoc(c, :streams),
        on: c.stream_id == s.id,
        join: u in assoc(c, :user),
        on: c.user_id == u.id,
        where:
          c.status == "live" and
            c.show_on_homepage and
            s.started_at <= ^fifteen_minutes_ago and
            is_nil(s.ended_at) and
            c.id in subquery(ten_hour_query),
        limit: 6,
        order_by: fragment("RANDOM()")
    )
  end

  defp get_max_slot_time do
    Repo.one!(from f in HomepageChannel, select: max(f.slot_ended_at))
  end

  defp create_homepage_channel!(%Channel{} = channel, slot_start, slot_end) do
    %HomepageChannel{}
    |> Changeset.change(%{
      slot_started_at: NaiveDateTime.truncate(slot_start, :second),
      slot_ended_at: NaiveDateTime.truncate(slot_end, :second)
    })
    |> Changeset.put_assoc(:channel, channel)
    |> Repo.insert!()
  end
end
