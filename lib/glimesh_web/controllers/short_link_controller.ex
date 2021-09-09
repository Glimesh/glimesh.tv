defmodule GlimeshWeb.ShortLinkController do
  use GlimeshWeb, :controller

  def event_form(conn, _params) do
    conn |> redirect(external: "https://forms.gle/6VpqMzc6i1XomaP86")
  end

  def community_discord(conn, _params) do
    conn |> redirect(external: "https://discord.gg/5TdhmkQSqT")
  end
end
