defmodule GlimeshWeb.InteractiveController do
  use GlimeshWeb, :controller
  alias Glimesh.ChannelLookups
  alias Glimesh.Interactive

  def index(conn, %{"username" => username}) do
    # Get the channel, serve the project
    channel = ChannelLookups.get_channel_for_username(username, true)

    if channel.interactive_project do
      # Serve the project
      conn |> redirect(to: Interactive.url({"index.html", channel}, :request))
    else
      not_found(conn, nil)
    end
  end

  def not_found(conn, _) do
    # The project doesn't exist :(
    conn
    |> put_resp_header("content-type", "text/html")
    |> put_resp_header("cache-control", "no-cache")
    |> send_file(200, "./priv/static/interactive/index.html")
  end

  def asset(conn, %{"id" => id, "asset" => asset}) do
    # Get the channel
    channel = ChannelLookups.get_channel_for_user_id(id, true)

    # Serve the project asset
    conn |> redirect(to: Interactive.url({Enum.join(asset, "/"), channel}, :request))
  end
end
