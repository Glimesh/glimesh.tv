defmodule GlimeshWeb.Plugs.FlocTest do
  use GlimeshWeb.ConnCase
  use ExUnit.Case

  test "adds a permission policy header to its conn", %{conn: conn} do
    assert conn
           |> GlimeshWeb.Plugs.Floc.call()
           |> Plug.Conn.get_resp_header("permissions-policy") == ["interest-cohort=()"]
  end
end
