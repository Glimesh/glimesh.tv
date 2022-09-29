defmodule GlimeshWeb.InteractiveController do
  use GlimeshWeb, :controller
  alias Glimesh.ChannelLookups

  def index(conn, %{"username" => username}) do
    # Get the channel, serve the project
    channel = ChannelLookups.get_channel_for_username(username, true)

    # Check if the users project exists. If it does, send it, if not send the default project
    # This is currently only local files. We will need to figure out the CDN later.
    case File.exists?("./uploads/interactive/#{channel.id}/index.html") do
      true -> conn |> redirect(to: "/uploads/interactive/#{channel.id}/index.html")
      false ->
        conn
        |> put_resp_header("Content-Type", "text/html")
        |> send_file( 200, "./priv/static/interactive/index.html")
    end
  end

  def not_found(conn, _) do
    # User requested incorrect path or the file doesn't exist
   conn |> redirect(to: "/priv/static/interactive/index.html")
  end
end
