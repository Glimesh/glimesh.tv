defmodule Glimesh.Charts.LiveStreams do
  @moduledoc false

  defmodule WeekData do
    @moduledoc false
    defstruct [:week_date, :streams_new]
  end

  defp query do
    """
    with timeframe as
    (
      select generate_series('2020-06-22', current_date, '1 week'::interval) week_date
    )
    select week_date,
      count(streams.*) as streams_new
    from timeframe
      left join streams on date_trunc('week', inserted_at) = date_trunc('week', week_date)
    group by week_date
    order by week_date;
    """
  end

  def json do
    chart(Glimesh.Charts.query_to_struct(query(), WeekData)) |> Jason.encode!()
  end

  def chart(data) do
    %{
      title: "Live Streams",
      series: [
        %{
          name: "Live Streams",
          data: Enum.map(data, fn x -> x.streams_new end)
        }
      ],
      label: %{
        type: "datetime",
        categories: Enum.map(data, fn x -> x.week_date end)
      }
    }
  end
end
