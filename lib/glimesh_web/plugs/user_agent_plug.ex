defmodule GlimeshWeb.Plugs.UserAgent do
  import Plug.Conn

  def init(_opts), do: nil

  def call(conn, _opts \\ []) do
    user_agent = get_req_header(conn, "user-agent")

    conn
    |> put_session(:user_agent, "#{user_agent}")
  end
end
