defmodule Glimesh.Formatters do
  @moduledoc """
  Common Glimesh Frontend Formatters

  Example uses: currency, date times, etc
  """

  def format_price(nil), do: "0.00"
  def format_price(iprice), do: :erlang.float_to_binary(iprice / 100, decimals: 2)

  def format_datetime(timestamp) when is_integer(timestamp) do
    format_datetime(DateTime.from_unix!(timestamp))
  end

  def format_datetime(%{year: _, month: _, day: _y} = datetime) do
    Calendar.strftime(datetime, "%b %d %Y")
  end

  def format_datetime(_), do: "Unknown"

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
    Phoenix.Component.assign(
      socket,
      :page_title,
      format_page_title(title)
    )
  end
end
