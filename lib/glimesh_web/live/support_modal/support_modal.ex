defmodule GlimeshWeb.SupportModal do
  use GlimeshWeb, :live_view

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:show_modal, false)
     |> assign(:streamer, streamer)
     |> assign(:user, nil)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])
    site_theme = session["site_theme"]

    {:ok,
     socket
     |> assign(:show_modal, false)
     |> assign(:site_theme, site_theme)
     |> assign(:tab, "subscription")
     |> assign(:streamer, streamer)
     |> assign(:user, user)}
  end

  @impl true
  def handle_event("show_modal", _value, socket) do
    {:noreply, socket |> assign(:show_modal, true)}
  end

  @impl true
  def handle_event("hide_modal", _value, socket) do
    {:noreply, socket |> assign(:show_modal, false)}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, socket |> assign(:tab, tab)}
  end
end
