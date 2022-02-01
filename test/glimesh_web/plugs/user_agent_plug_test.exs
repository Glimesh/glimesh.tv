defmodule GlimeshWeb.Plugs.UserAgentTest do
  use GlimeshWeb.ConnCase
  use ExUnit.Case

  test "adds user-agent header to the session", %{conn: conn} do
    conn =
      conn
      |> Plug.Test.init_test_session(%{})
      |> put_req_header("user-agent", "test agent")

    assert conn
           |> Plug.Conn.fetch_session()
           |> GlimeshWeb.Plugs.UserAgent.call()
           |> Plug.Conn.get_session("user_agent") == "test agent"
  end
end
