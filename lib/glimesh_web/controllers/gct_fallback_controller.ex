defmodule GlimeshWeb.GCTFallbackController do
  use GlimeshWeb, :controller

  alias Glimesh.CommunityTeam

  def call(conn, {:error, :unauthorized}) do
    CommunityTeam.log_unauthorized_access(conn.assigns.current_user)
    conn
    |> put_flash(:error, "Unauthorized. This attempt has been logged.")
    |> render("unauthorized.html")
  end
end
