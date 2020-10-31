defmodule GlimeshWeb.Plugs.Ban do
  alias GlimeshWeb.UserAuth

  def init(_opts), do: nil

  def call(conn, _opts) do
    user = conn.assigns.current_user

    if is_user_banned(user) do
      conn
      |> UserAuth.ban_user()
      |> replace_path("/")
    else
      conn
    end
  end

  defp is_user_banned(user) do
    case user do
      nil -> false
      _ -> if user.is_banned, do: true, else: false
    end
  end

  defp replace_path(conn, path) do
    conn
    |> Map.replace!(:request_path, path)
    |> Map.replace!(:path_info, ["banned"])
  end
end
