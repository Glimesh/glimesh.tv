defmodule GlimeshWeb.TakeoutController do
  use GlimeshWeb, :controller

  plug :put_layout, "user-sidebar.html"

  def index(conn, _params) do
    render(conn, "index.html", page_title: format_page_title(gettext("Takeout")))
  end

  def download(conn, _params) do
    {:ok, {filename, bytes}} = Glimesh.Takeout.export_user(conn.assigns.current_user)
    conn |> send_download({:binary, bytes}, filename: filename)
  end
end
