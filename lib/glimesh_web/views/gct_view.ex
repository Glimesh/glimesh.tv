defmodule GlimeshWeb.GctView do
  use GlimeshWeb, :view

  def format_price(nil), do: "0.00"
  def format_price(iprice), do: :erlang.float_to_binary(iprice / 100, decimals: 2)

  def format_datetime(nil), do: "Unknown"

  def format_datetime(timestamp) when is_integer(timestamp) do
    d = DateTime.from_unix!(timestamp)
    "#{d.year}/#{d.month}/#{d.day}"
  end

  def format_datetime(%{year: year, month: month, day: day}) do
    "#{year}/#{month}/#{day}"
  end
end
