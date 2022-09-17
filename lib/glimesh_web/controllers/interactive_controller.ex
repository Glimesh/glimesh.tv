defmodule GlimeshWeb.InteractiveController do
  use GlimeshWeb, :controller
  alias Glimesh.ChannelLookups

  def index(conn, %{"username" => username}) do
    # Get the channel, serve the project
    channel = ChannelLookups.get_channel_for_username(username, true)

    conn |> redirect(to: "/uploads/interactive/#{channel.id}/index.html")
  end

  def not_found(conn, _) do
    # User requested incorrect path or the file doesn't exist
    send_resp(conn, 404, "Not found")
  end
end
