defmodule GlimeshWeb.Plugs.Floc do
  @moduledoc """
  Pluggable header to opt out of Google FLoC
  """

  def init(_opts), do: nil

  def call(conn, _opts \\ []) do
    Plug.Conn.put_resp_header(conn, "permissions-policy", "interest-cohort=()")
  end
end
