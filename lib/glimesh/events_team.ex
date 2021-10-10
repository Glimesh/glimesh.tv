defmodule Glimesh.EventsTeam do
  @moduledoc """
  The EventsTeam context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset

  alias Glimesh.EventsTeam.Event
  alias Glimesh.Repo

  def list_events do
    Repo.all(
      from e in Event,
        order_by: [desc: e.start_date]
    )
    |> Enum.map(fn x -> times_from_utc(x) end)
  end

  def list_featured_events do
    now = DateTime.utc_now()

    Repo.all(
      from e in Event,
        where: e.featured == true,
        where: e.end_date >= ^now,
        order_by: [asc: e.end_date],
        limit: 5
    )
    |> Enum.map(fn x -> times_from_utc(x) end)
  end

  def get_day_ordinal(date) do
    case date.day do
      1 -> "st"
      2 -> "nd"
      3 -> "rd"
      21 -> "st"
      22 -> "nd"
      23 -> "rd"
      31 -> "st"
      _ -> "th"
    end
  end

  def get_event(eventid) do
    Repo.get_by!(Glimesh.EventsTeam.Event, id: eventid)
    |> times_from_utc()
    |> Event.changeset()
  end

  def list_events_in_month(from, to) do
    Repo.all(
      from e in Event,
        where: e.end_date >= ^from,
        where: e.start_date <= ^to,
        order_by: [asc: e.start_date]
    )
  end

  def empty_event do
    Event.changeset(%Event{}, %{
      "id" => 0,
      "start_date" => DateTime.now!("America/New_York", Tzdata.TimeZoneDatabase),
      "end_date" => DateTime.now!("America/New_York", Tzdata.TimeZoneDatabase)
    })
  end

  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> times_to_utc()
    |> Repo.insert()
  end

  def update_event(attrs \\ %{}) do
    %Event{id: String.to_integer(attrs["id"])}
    |> Event.changeset(attrs)
    |> times_to_utc()
    |> Repo.update()
  end

  def delete_event(eventid) do
    %Event{id: String.to_integer(eventid)}
    |> Event.changeset()
    |> Repo.delete()
  end

  def list_types do
    Keyword.get(Application.get_env(:glimesh, :event_type), :event_labels, [])
  end

  defp times_to_utc(changeset) do
    start_time =
      DateTime.from_naive!(
        get_field(changeset, :start_date),
        "America/New_York",
        Tzdata.TimeZoneDatabase
      )

    end_time =
      DateTime.from_naive!(
        get_field(changeset, :end_date),
        "America/New_York",
        Tzdata.TimeZoneDatabase
      )

    start_time_utc = DateTime.shift_zone!(start_time, "Etc/UTC", Tzdata.TimeZoneDatabase)
    end_time_utc = DateTime.shift_zone!(end_time, "Etc/UTC", Tzdata.TimeZoneDatabase)

    changeset
    |> put_change(:start_date, DateTime.to_naive(start_time_utc))
    |> put_change(:end_date, DateTime.to_naive(end_time_utc))
  end

  defp times_from_utc(%Event{} = event) do
    start_time = DateTime.from_naive!(event.start_date, "Etc/UTC", Tzdata.TimeZoneDatabase)
    end_time = DateTime.from_naive!(event.end_date, "Etc/UTC", Tzdata.TimeZoneDatabase)

    start_time_glimtime =
      DateTime.shift_zone!(start_time, "America/New_York", Tzdata.TimeZoneDatabase)

    end_time_glimtime =
      DateTime.shift_zone!(end_time, "America/New_York", Tzdata.TimeZoneDatabase)

    %Event{
      event
      | start_date: DateTime.to_naive(start_time_glimtime),
        end_date: DateTime.to_naive(end_time_glimtime)
    }
  end

  def date_to_utc(date) do
    raw_date = DateTime.from_naive!(date, "America/New_York", Tzdata.TimeZoneDatabase)
    DateTime.shift_zone!(raw_date, "Etc/UTC", Tzdata.TimeZoneDatabase)
  end

  def live_now(%Event{} = event) do
    now =
      DateTime.to_naive(
        DateTime.shift_zone!(DateTime.utc_now(), "America/New_York", Tzdata.TimeZoneDatabase)
      )

    # throw(NaiveDateTime.compare(event.end_date, now))
    NaiveDateTime.compare(event.start_date, now) == :lt and
      NaiveDateTime.compare(event.end_date, now) == :gt
  end
end
