defmodule GlimeshWeb.Plugs.CfCountryPlug do
  import Plug.Conn

  def init(_opts), do: nil

  def call(conn, _opts) do
    conn
    |> persist_country(get_req_header(conn, "cf-ipcountry"))
    |> persist_ip_address(get_req_header(conn, "cf-connecting-ip"))
  end

  defp persist_country(conn, [country]) when is_binary(country) do
    conn
    |> put_session(:country, String.upcase(country))
  end

  defp persist_country(conn, _) do
    conn
  end

  defp persist_ip_address(conn, [ip_address]) when is_binary(ip_address) do
    case ip_address |> String.to_charlist() |> :inet.parse_address() do
      {:ok, remote_ip} -> %Plug.Conn{conn | remote_ip: remote_ip}
      {:error, _} -> conn
    end
  end

  defp persist_ip_address(conn, _) do
    conn
  end
end
