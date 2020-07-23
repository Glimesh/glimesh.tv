defmodule GlimeshWeb.PageLive do
  use GlimeshWeb, :live_view

  alias Glimesh.Streams

  @impl true
  def mount(params, _session, socket) do
    {:ok, socket
          |> assign(:page_title, params["category"])
          |> assign(:category, params["category"])
          |> assign(:show_banner, is_nil(params["category"]))
          |> assign(:streams,  Streams.list_streams())}
  end
end
