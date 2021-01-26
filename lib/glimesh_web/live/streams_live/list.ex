defmodule GlimeshWeb.StreamsLive.List do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.Streams

  @impl true
  def mount(%{"category" => "following"}, session, socket) do
    case Accounts.get_user_by_session_token(session["user_token"]) do
      %Glimesh.Accounts.User{} = user ->
        if session["locale"], do: Gettext.put_locale(session["locale"])

        channels = Glimesh.Streams.list_live_followed_channels(user)

        {:ok,
         socket
         |> put_page_title(gettext("Followed Streams"))
         |> assign(:list_name, "Followed")
         |> assign(:channels, channels)}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  @impl true
  def mount(%{"category" => category}, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    case Streams.get_category(category) do
      %Glimesh.Streams.Category{} = category ->
        channels = Glimesh.Streams.list_in_category(category)

        {:ok,
         socket
         |> put_page_title(category.name)
         |> assign(:list_name, category.name)
         |> assign(:channels, channels)
         |> assign(:category, category)}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  def mount(_, _, socket) do
    {:ok, redirect(socket, to: "/")}
  end
end
