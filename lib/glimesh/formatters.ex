defmodule Glimesh.Formatters do
  @moduledoc """
  Common Glimesh Frontend Formatters

  Example uses: currency, date times, etc
  """

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

  def format_page_title(nil) do
    "Glimesh"
  end

  def format_page_title(title) do
    "#{title} - Glimesh"
  end

  def put_page_title(socket) do
    put_page_title(socket, nil)
  end

  def put_page_title(%Phoenix.LiveView.Socket{} = socket, title) do
    Phoenix.LiveView.assign(
      socket,
      :page_title,
      format_page_title(title)
    )
  end
end
