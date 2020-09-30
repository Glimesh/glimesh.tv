defmodule Glimesh.Charts.PlatformUserGrowth do
  @moduledoc false

  defmodule WeekData do
    @moduledoc false
    defstruct [:week_date, :users_new, :users_total]
  end

  defp query do
    """
    with timeframe as
    (
      select generate_series('2020-06-22', current_date, '1 week'::interval) week_date
    )
    select week_date,
      count(users.*)                            as users_new,
      sum(count(users.*)) over (order by week_date) as users_total
    from timeframe
      left join users on date_trunc('week', inserted_at) = date_trunc('week', week_date)
    group by week_date
    order by week_date;
    """
  end

  def json do
    chart(Glimesh.Charts.query_to_struct(query(), WeekData)) |> Jason.encode!()
  end

  def chart(data) do
    %{
      title: "Platform User Growth",
      series: [
        %{
          name: "New Users",
          data: Enum.map(data, fn x -> x.users_new end)
        },
        %{
          name: "Total Users",
          data: Enum.map(data, fn x -> x.users_total end)
        }
      ],
      label: %{
        type: "datetime",
        categories: Enum.map(data, fn x -> x.week_date end)
      }
    }
  end
end
