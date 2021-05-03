defmodule GlimeshWeb.UserLive.Stream do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.ChannelLookups
  alias Glimesh.Streams

  def mount(%{"username" => streamer_username}, session, socket) do
    case ChannelLookups.get_channel_for_username(streamer_username) do
      %Glimesh.Streams.Channel{} = channel ->
        if session["locale"], do: Gettext.put_locale(session["locale"])

        if connected?(socket) do
          # Wait until the socket connection is ready to load the stream
          Process.send(self(), :load_stream, [])
          Streams.subscribe_to(:channel, channel.id)
        end

        streamer = Accounts.get_user!(channel.streamer_id)

        {:ok,
         socket
         |> put_page_title(channel.title)
         |> assign(:streamer, channel.user)
         |> assign(:channel, channel)
         |> assign(:stream, channel.stream)}

      nil ->
        {:ok, redirect(socket, to: "/#{streamer_username}/profile")}
    end
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end
end
