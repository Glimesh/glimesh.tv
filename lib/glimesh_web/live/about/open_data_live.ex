defmodule GlimeshWeb.About.OpenDataLive do
  use GlimeshWeb, :live_view

  @impl true
  def mount(_, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> assign(:chart_data, Jason.encode!(%{}))
     |> assign(:chart_theme, Map.get(session, "site_theme", "dark"))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _) do
    socket |> assign(:chart_data, Glimesh.Charts.PlatformUserGrowth.json())
  end

  defp apply_action(socket, :subscriptions, _) do
    socket |> assign(:chart_data, Glimesh.Charts.RecurringSubscriptions.json())
  end

  defp apply_action(socket, :streams, _) do
    socket |> assign(:chart_data, Glimesh.Charts.LiveStreams.json())
  end
end
