defmodule GlimeshWeb.InteractiveController do
  use GlimeshWeb, :controller
  alias Glimesh.ChannelLookups

  def index(conn, %{"username" => username}) do
    channel = ChannelLookups.get_channel_for_username(username, true)

    conn |> redirect(to: "/uploads/interactive/#{channel.id}/index.html")
  end
end
