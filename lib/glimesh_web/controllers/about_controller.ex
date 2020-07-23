defmodule GlimeshWeb.AboutController do
  use GlimeshWeb, :controller

  plug :put_layout, "text.html"

  def index(conn, _param) do
    render(conn, "index.html", page_title: "About Us", subtitle: "")
  end

  def faq(conn, _param) do
    render(conn, "faq.html", page_title: "F.A.Q",  subtitle: "Frequently Answered Questions!")
  end

  def privacy(conn, _param) do
    render(conn, "privacy.html", page_title: "Privacy & Cookie Policy", subtitle: "They are delicious, but they are yours!")
  end

  def terms(conn, _param) do
    render(conn, "terms.html", page_title: "Terms of Service", subtitle: "")
  end

end
