defmodule Glimesh.Charts.RecurringSubscriptions do
  @moduledoc false

  defmodule WeekData do
    @moduledoc false
    defstruct [:week_date, :cents_new, :cents_total]
  end

  defp query do
    """
    with timeframe as
    (
      select generate_series('2020-06-22', current_date, '1 week'::interval) week_date
    )
    select week_date,
      coalesce(sum(subscriptions.price), 0)                                as cents_new,
      sum(coalesce(sum(subscriptions.price), 0)) over (order by week_date) as cents_total
    from timeframe
      left join subscriptions on date_trunc('week', inserted_at) = date_trunc('week', week_date)
    group by week_date
    order by week_date;
    """
  end

  def json do
    chart(Glimesh.Charts.query_to_struct(query(), WeekData)) |> Jason.encode!()
  end

  def chart(data) do
    %{
      title: "Recurring Subscriptions",
      series: [
        %{
          name: "New Subscription Dollars",
          data: Enum.map(data, fn x -> format_price(x.cents_new) end)
        },
        %{
          name: "Active Subscription Total Dollars",
          data: Enum.map(data, fn x -> format_price(x.cents_total) end)
        }
      ],
      label: %{
        type: "datetime",
        categories: Enum.map(data, fn x -> x.week_date end)
      },
      series_format: "money"
    }
  end

  defp format_price(nil), do: "0.00"

  defp format_price(%Decimal{} = iprice) do
    :erlang.float_to_binary(Decimal.to_float(iprice) / 100, decimals: 2)
  end

  defp format_price(iprice),
    do: :erlang.float_to_binary(iprice / 100, decimals: 2)
end
