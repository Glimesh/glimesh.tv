defmodule GlimeshWeb.AboutController do
  use GlimeshWeb, :controller

  plug :put_layout, "about.html"

  def index(conn, _param) do
    render(conn, "index.html", page_title: format_page_title(gettext("About Glimesh")))
  end

  def streaming(conn, _param) do
    render(conn, "streaming.html", page_title: format_page_title(gettext("Streaming")))
  end

  def team(conn, _param) do
    users = Glimesh.Accounts.list_team_users()

    render(conn, "team.html",
      page_title: format_page_title(gettext("The Team")),
      users: users
    )
  end

  def mission(conn, _param) do
    render(conn, "mission.html", page_title: format_page_title(gettext("Our Mission")))
  end

  # Other layouts

  def faq(conn, _param) do
    conn
    |> put_layout("text.html")
    |> render("faq.html", page_title: format_page_title(gettext("Frequently Asked Questions")))
  end

  def privacy(conn, _param) do
    conn
    |> put_layout("text.html")
    |> render("privacy.html", page_title: format_page_title(gettext("Privacy & Cookie Policy")))
  end

  def terms(conn, _param) do
    conn
    |> put_layout("text.html")
    |> render("terms.html", page_title: format_page_title(gettext("Terms of Service")))
  end

  def dmca(conn, _params) do
    conn
    |> put_layout("app.html")
    |> render("dmca.html",
      page_title: format_page_title(gettext("DMCA"))
    )
  end

  def credits(conn, _param) do
    %{
      ftl: ftl_credits,
      node: node_credits,
      elixir: elixir_credits
    } = Glimesh.Credits.get_dependencies()

    founder_subscribers = Glimesh.Payments.list_platform_founder_subscribers()
    supporter_subscribers = Glimesh.Payments.list_platform_supporter_subscribers()

    conn
    |> put_layout("text.html")
    |> render("credits.html",
      page_title: format_page_title(gettext("Credits")),
      ftl_credits: ftl_credits,
      elixir_credits: elixir_credits,
      node_credits: node_credits,
      founder_subscribers: founder_subscribers,
      supporter_subscribers: supporter_subscribers
    )
  end
end
