defmodule GlimeshWeb.Plugs.CfCountryPlug do
  import Plug.Conn

  def init(_opts), do: nil

  def call(conn, _opts) do
    case get_req_header(conn, "cf-ipcountry") do
      [country] when is_binary(country) ->
        persist_country(conn, country)

      _ ->
        conn
    end
  end

  defp persist_country(conn, country) do
    conn
    |> put_session(:country, String.upcase(country))
  end
end
