defmodule GlimeshWeb.AboutController do
  use GlimeshWeb, :controller

  plug :put_layout, "text.html"

  def index(conn, _param) do
    render(conn, "index.html", page_title: "About Us", subtitle: "")
  end

  def faq(conn, _param) do
    render(conn, "faq.html", page_title: "F.A.Q", subtitle: "Frequently Answered Questions!")
  end

  def privacy(conn, _param) do
    render(conn, "privacy.html",
      page_title: "Privacy & Cookie Policy",
      subtitle: "They are delicious, but they are yours!"
    )
  end

  def terms(conn, _param) do
    render(conn, "terms.html", page_title: "Terms of Service", subtitle: "")
  end

  def credits(conn, _param) do
    %{
      ftl: ftl_credits,
      node: node_credits,
      elixir: elixir_credits
    } = Glimesh.Credits.get_dependencies()

    founder_subscribers = Glimesh.Payments.list_platform_founder_subscribers()
    supporter_subscribers = Glimesh.Payments.list_platform_supporter_subscribers()

    render(conn, "credits.html",
      page_title: "Credits",
      subtitle: "",
      ftl_credits: ftl_credits,
      elixir_credits: elixir_credits,
      node_credits: node_credits,
      founder_subscribers: founder_subscribers,
      supporter_subscribers: supporter_subscribers
    )
  end
end
