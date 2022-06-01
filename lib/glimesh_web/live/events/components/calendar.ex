defmodule GlimeshWeb.Events.Components.Calendar do
  use GlimeshWeb, :surface_live_component

  alias Calendar.ISO
  alias Glimesh.EventsTeam.Event

  data calendar_title, :string
  data weeks, :list
  data current_month, :string
  data current_year, :string
  data event_types_key, :list

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <div class="calendar" style="width: 100%">
        <div class="d-flex calendar_header">
          <div
            class="left p-2"
            :on-click="last_month"
            phx-value-month={@current_month}
            phx-value-year={@current_year}
          >
            <i class="fas fa-chevron-left" />
          </div>

          <div class="flex-grow-1 header_month">{@calendar_title}</div>

          <div
            class="right p-2"
            :on-click="next_month"
            phx-value-month={@current_month}
            phx-value-year={@current_year}
          >
            <i class="fas fa-chevron-right" />
          </div>
        </div>
      </div>

      <div class="calendar">
        <div class="week d-flex">
          <div class="flex-grow-1 pt-2 day day-name">Mon</div>

          <div class="flex-grow-1 pt-2 day day-name">Tue</div>

          <div class="flex-grow-1 pt-2 day day-name">Wed</div>

          <div class="flex-grow-1 pt-2 day day-name">Thu</div>

          <div class="flex-grow-1 pt-2 day day-name">Fri</div>

          <div class="flex-grow-1 pt-2 day day-name">Sat</div>

          <div class="flex-grow-1 pt-2 day day-name">Sun</div>
        </div>

        {#for week <- @weeks}
          <div class="week d-flex">
            {#for day <- week.days}
              <div class={[
                "flex-grow-1 p-1 day day-number",
                if(not day.in_month, do: "disabled"),
                if(day.today, do: "today"),
                if(day.selected, do: "selected")
              ]}>
                {#if day.in_month}
                  <div
                    :on-click="select_day"
                    phx-value-month={@current_month}
                    phx-value-year={@current_year}
                    phx-value-day={day.day}
                  >
                    {day.day}
                    <br>

                    {#for event <- day.todays_events}
                      <div
                        class="calendar-event"
                        style={"border-color: #{get_event_color(event)}; background: #{get_event_color(event)};"}
                        title={event.label}
                      >
                      </div>
                    {/for}
                  </div>
                {#else}
                  <div>
                    {day.day}
                    <br>

                    {#for event <- day.todays_events}
                      <div
                        class="calendar-event"
                        style={"border-color: #{get_event_color(event)}; background: #{get_event_color(event)};"}
                        title={event.label}
                      >
                      </div>
                    {/for}
                  </div>
                {/if}
              </div>
            {/for}
          </div>

          {#if week.expanded}
            <div class="events_header">
              <ul class="list-unstyled mb-0 py-2">
                {#for event <-
                    week.days
                    |> Enum.filter(fn x -> x.selected end)
                    |> Enum.map(fn x -> x.todays_events end)
                    |> List.first()}
                  <li class="text-left">
                    <div
                      class="calendar-event ml-2 mr-2"
                      style={"border-color: #{get_event_color(event)}; background: #{get_event_color(event)};"}
                    >
                    </div>
                    <a href={"#event#{event.id}"} class="text-color-link text-color-link-no-hover">
                      {event.label} at {Calendar.strftime(event.start_date, "%I:%M %p")}
                      Eastern
                    </a>
                  </li>
                {/for}
              </ul>
            </div>
          {/if}
        {/for}
      </div>

      <div class="calendar" style="width: 100%">
        <div class="d-flex justify-content-around calendar_footer py-2">
          {#for event_type <- @event_types_key}
            <!-- Temporary text color change to enhance readability on Pride tag -->
            <span
              class="badge badge-pill text-dark"
              style={"vertical-align: middle; border-color: #{event_type.color}; background: #{event_type.color}"}
            >
              {event_type.label}
            </span>
          {/for}
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    today_date = DateTime.utc_now()

    current_month = today_date.month()
    current_year = today_date.year()

    calendar_title = Calendar.strftime(Date.new!(current_year, current_month, 1), "%B %Y")

    {:ok,
     socket
     |> assign(:conn, socket)
     |> assign(:today_date, today_date)
     |> assign(:current_month, current_month)
     |> assign(:current_year, current_year)
     |> assign(:calendar_title, calendar_title)
     |> assign(:weeks, get_weeks(current_month, current_year, nil))
     |> assign(:event_types_key, get_key())}
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
