defmodule GlimeshWeb.Plugs.Cors do
  @moduledoc """
  Something somethinv cors
  """

  def init(_opts), do: nil

  def call(conn, _opts \\ []) do
    Plug.Conn.put_resp_header(conn, "access-control-allow-origin", "*")
  end
end
