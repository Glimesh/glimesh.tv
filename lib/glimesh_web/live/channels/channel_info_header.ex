defmodule GlimeshWeb.Channels.ChannelInfoHeader do
  use GlimeshWeb, :live_view

  alias Glimesh.Presence
  alias Glimesh.Streams

  @impl Phoenix.LiveView
  def render(assigns) do
    ~L"""
    <h1>Header</h1>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    {:ok, socket}
  end
end
