defmodule GlimeshWeb.UniqueUserPlug do
  @moduledoc """
  The intention of this module is to provide us a semi-identifying hash for an actual unique user.any()

  Currently if the user is not logged in, it defaults to the IP Address.
  If the user is logged in, it combines the IP Address with the User ID to support shared households / colleges.
  """
  import Plug.Conn

  def init(_opts), do: nil

  def call(conn, _opts) do
    conn
    |> put_unique_token()
  end

  def put_unique_token(conn) do
    current_user = Map.get(conn.assigns, :current_user, %{})
    ip_address = conn.remote_ip |> :inet.ntoa() |> to_string()

    case current_user do
      %{id: id} ->
        conn |> put_session(:unique_user, hash(ip_address, id))

      _ ->
        conn |> put_session(:unique_user, hash(ip_address, 0))
    end
  end

  defp hash(ip_address, user_id) do
    :crypto.hash(:sha256, "#{ip_address}-#{user_id}")
    |> Base.encode16()
    |> String.downcase()
  end
end
