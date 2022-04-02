defmodule Glimesh.Charts.RecurringSubscriptions do
  @moduledoc false

  defmodule WeekData do
    @moduledoc false
    defstruct [:week_date, :platform_cut, :streamer_cut]
  end

  defp query do
    """
    with timeframe as
    (
         select generate_series('2021-03-01', current_date, '1 month'::interval) week_date
    )
    select week_date,
      coalesce(sum(cs.our_fees), 0) as platform_cut,
      coalesce(sum(cs.payout_amount), 0)                                             as streamer_cut
    from timeframe
        join payables cs on date_trunc('month', cs.inserted_at) = date_trunc('month', week_date)
    where cs.user_paid_at is not null
    and cs.type = 'subscription'
    and cs.streamer_id is not null
    group by week_date
    order by week_date;
    """
  end

  def json do
    Glimesh.QueryCache.get_and_store!("Glimesh.Charts.RecurringSubscriptions.json()", fn ->
      {:ok, chart(Glimesh.Charts.query_to_struct(query(), WeekData)) |> Jason.encode!()}
    end)
  end

  def chart(data) do
    %{
      title: "Recurring Subscriptions",
      series: [
        %{
          name: "Platform Cut",
          data: Enum.map(data, fn x -> format_price(x.platform_cut) end)
        },
        %{
          name: "Streamer Cut",
          data: Enum.map(data, fn x -> format_price(x.streamer_cut) end)
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
