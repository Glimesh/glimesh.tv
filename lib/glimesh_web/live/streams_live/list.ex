defmodule GlimeshWeb.StreamsLive.List do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Streams

  @impl true
  def mount(%{"category" => "following"}, session, socket) do
    user = Accounts.get_user_by_session_token(session["user_token"])
    Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:page_title, dgettext("streams", "Followed Streams"))
     |> assign(:category, dgettext("streams", "Followed"))
     |> assign(:show_banner, false)
     |> assign(:streams, Streams.list_followed_streams(user))}
  end

  @impl true
  def mount(params, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    case Streams.get_category!(params["category"]) do
      %Glimesh.Streams.Category{} = category ->
        page = Glimesh.StreamLayout.CategoryHomepage.generate_category_page(category)

        {:ok,
         socket
         |> assign(:page_title, category.name)
         |> assign(:category, category)
         |> assign(:page, page)}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end
end
