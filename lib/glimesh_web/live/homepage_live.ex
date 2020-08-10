defmodule GlimeshWeb.HomepageLive do
  use GlimeshWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    {:ok, socket |> assign(:page_title, "Glimesh")}
  end
end
