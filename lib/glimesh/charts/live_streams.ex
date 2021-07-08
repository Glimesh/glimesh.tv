defmodule Glimesh.Charts.LiveStreams do
  @moduledoc false

  defmodule WeekData do
    @moduledoc false
    defstruct [:week_date, :unique_streamers, :peak_viewers]
  end

  defp query do
    """
    with timeframe as
         (
             select generate_series('2021-03-08', current_date, '1 week'::interval) week_date
         )
    select week_date,
       count(distinct streams.channel_id) as unique_streamers,
       sum(streams.peak_viewers) as peak_viewers
    from timeframe
         left join streams on date_trunc('week', inserted_at) = date_trunc('week', week_date)
    group by week_date
    order by week_date;
    """
  end

  def json do
    Glimesh.QueryCache.get_and_store!("Glimesh.Charts.LiveStreams.json()", fn ->
      {:ok, chart(Glimesh.Charts.query_to_struct(query(), WeekData)) |> Jason.encode!()}
    end)
  end

  def chart(data) do
    %{
      title: "Live Streams",
      series: [
        %{
          name: "Unique Streamers",
          data: Enum.map(data, fn x -> x.unique_streamers end)
        },
        %{
          name: "Peak Viewers",
          data: Enum.map(data, fn x -> x.peak_viewers end)
        }
      ],
      label: %{
        type: "datetime",
        categories: Enum.map(data, fn x -> x.week_date end)
      }
    }
  end
end
