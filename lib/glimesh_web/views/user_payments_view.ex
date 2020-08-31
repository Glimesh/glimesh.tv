defmodule GlimeshWeb.UserPaymentsView do
  use GlimeshWeb, :view

  def format_price(nil), do: "0.00"
  def format_price(iprice), do: :erlang.float_to_binary(iprice / 100, decimals: 2)
end
