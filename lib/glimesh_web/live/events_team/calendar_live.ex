defmodule GlimeshWeb.CalendarLive do
  use GlimeshWeb, :live_view

  alias Calendar.ISO
  alias Glimesh.EventsTeam.Event

  @impl true
  def mount(_params, _session, socket) do
    today_date = DateTime.utc_now()

    current_month = today_date.month()
    current_year = today_date.year()

    calendar_title = Calendar.strftime(Date.new!(current_year, current_month, 1), "%B %Y")

    new_socket =
      socket
      |> assign(:conn, socket)
      |> assign(:today_date, today_date)
      |> assign(:current_month, current_month)
      |> assign(:current_year, current_year)
      |> assign(:calendar_title, calendar_title)
      |> assign(:weeks, get_weeks(current_month, current_year, nil))
      |> assign(:event_types_key, get_key())

    {:ok, new_socket}
  end

  @impl true
  def handle_event("last_month", value, socket) do
    current_month = String.to_integer(Map.fetch!(value, "month"))
    current_year = String.to_integer(Map.fetch!(value, "year"))

    {current_month, current_year} =
      if current_month == 1, do: {12, current_year - 1}, else: {current_month - 1, current_year}

    calendar_title = Calendar.strftime(Date.new!(current_year, current_month, 1), "%B %Y")

    {:noreply,
     socket
     |> assign(:current_month, current_month)
     |> assign(:current_year, current_year)
     |> assign(:calendar_title, calendar_title)
     |> assign(:weeks, get_weeks(current_month, current_year, nil))
     |> assign(:event_types_key, get_key())}
  end

  @impl true
  def handle_event("next_month", value, socket) do
    current_month = String.to_integer(Map.fetch!(value, "month"))
    current_year = String.to_integer(Map.fetch!(value, "year"))

    {current_month, current_year} =
      if current_month == 12, do: {1, current_year + 1}, else: {current_month + 1, current_year}

    calendar_title = Calendar.strftime(Date.new!(current_year, current_month, 1), "%B %Y")

    {:noreply,
     socket
     |> assign(:current_month, current_month)
     |> assign(:current_year, current_year)
     |> assign(:calendar_title, calendar_title)
     |> assign(:weeks, get_weeks(current_month, current_year, nil))
     |> assign(:event_types_key, get_key())}
  end

  @impl true
  def handle_event("select_day", value, socket) do
    current_month = String.to_integer(Map.fetch!(value, "month"))
    current_year = String.to_integer(Map.fetch!(value, "year"))
    current_day = String.to_integer(Map.fetch!(value, "day"))
    calendar_title = Calendar.strftime(Date.new!(current_year, current_month, 1), "%B %Y")

    {:noreply,
     socket
     |> assign(:current_month, current_month)
     |> assign(:current_year, current_year)
     |> assign(:calendar_title, calendar_title)
     |> assign(:weeks, get_weeks(current_month, current_year, current_day))
     |> assign(:event_types_key, get_key())}
  end

  defp get_weeks(month, year, day) do
    today_date = DateTime.to_date(DateTime.utc_now())
    start_of_month = Date.new!(year, month, 1)
    end_of_month = Date.add(start_of_month, ISO.days_in_month(year, month) - 1)
    first_day_of_week = ISO.day_of_week(year, month, 1)

    end_day_of_month = ISO.day_of_week(end_of_month.year, end_of_month.month, end_of_month.day)

    start_of_display = Date.add(start_of_month, (first_day_of_week - 1) * -1)
    end_of_display = Date.add(end_of_month, 7 - end_day_of_month)

    events =
      Glimesh.EventsTeam.list_events_in_month(
        NaiveDateTime.new!(start_of_display, ~T[00:00:00.000]),
        NaiveDateTime.new!(end_of_display, ~T[23:59:59.999])
      )

    Date.range(start_of_display, end_of_display)
    |> Enum.map(fn x ->
      %{
        day: Calendar.strftime(x, "%d"),
        in_month: x.month == month,
        today: x == today_date,
        selected: x.month == month and x.day == day,
        todays_events:
          events
          |> Enum.filter(fn e ->
            NaiveDateTime.compare(e.start_date, NaiveDateTime.new!(x, ~T[00:00:00.000])) != :lt and
              NaiveDateTime.compare(e.start_date, NaiveDateTime.new!(x, ~T[23:59:59.999])) != :gt
          end)
      }
    end)
    |> Enum.chunk_every(7)
    |> Enum.map(fn x ->
      %{
        days: x,
        expanded: Enum.any?(x, fn y -> y.selected end)
      }
    end)
  end

  defp get_key do
    labels =
      Keyword.to_list(Keyword.get(Application.get_env(:glimesh, :event_type), :event_labels, []))

    Keyword.to_list(Keyword.get(Application.get_env(:glimesh, :event_type), :event_colors, []))
    |> Enum.map(fn x ->
      %{
        label:
          labels
          |> Enum.filter(fn y -> elem(y, 0) == elem(x, 0) end)
          |> Enum.map(fn y -> elem(y, 1) end)
          |> List.first(),
        color: elem(x, 1)
      }
    end)
  end

  def get_event_color(%Event{} = event) do
    labels =
      Keyword.to_list(Keyword.get(Application.get_env(:glimesh, :event_type), :event_labels, []))

    Keyword.to_list(Keyword.get(Application.get_env(:glimesh, :event_type), :event_colors, []))
    |> Enum.filter(fn x ->
      key =
        labels
        |> Enum.filter(fn y -> elem(y, 1) == event.type end)
        |> List.first()

      elem(key, 0) == elem(x, 0)
    end)
    |> Enum.map(fn x -> elem(x, 1) end)
    |> List.first()
  end
end
