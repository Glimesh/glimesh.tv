defmodule GlimeshWeb.ShortLinkController do
  use GlimeshWeb, :controller

  def event_form(conn, _params) do
    conn |> redirect(external: "https://forms.gle/6VpqMzc6i1XomaP86")
  end
end
