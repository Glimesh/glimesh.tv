defmodule GlimeshWeb.HomepageLive do
  use GlimeshWeb, :live_view
  alias Glimesh.Accounts

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    maybe_user = Accounts.get_user_by_session_token(session["user_token"])
    # If the viewer is logged in set their locale, otherwise it defaults to English
    if session["locale"], do: Gettext.put_locale(session["locale"])

    channels = get_cached_channels()

    random_channel = get_random_channel(channels)
    # Temporarily making GCX the default homepage stream when they are live
    random_channel = get_gcx_or_random(random_channel)

    user_count = Glimesh.Accounts.count_users()

    {:ok,
     socket
     |> put_page_title()
     |> assign(:channels, channels)
     |> assign(:random_channel, random_channel)
     |> assign(:random_channel_thumbnail, get_stream_thumbnail(random_channel))
     |> assign(:user_count, user_count)
     |> assign(:current_user, maybe_user)}
  end

  defp get_gcx_or_random(random_channel) do
    now = NaiveDateTime.utc_now()

    maybe_gcx_channel = Glimesh.ChannelLookups.search_live_channels(%{"ids" => ["15710"]})

    # Slightly larger slots just in case
    gcx_slots = [
      [~N[2021-06-17 15:00:00], ~N[2021-06-17 21:00:00]],
      [~N[2021-06-18 15:00:00], ~N[2021-06-18 21:00:00]],
      [~N[2021-06-19 15:00:00], ~N[2021-06-19 21:00:00]]
    ]

    gcx_live? =
      Enum.any?(gcx_slots, fn [start_time, end_time] ->
        now > start_time and now < end_time
      end)

    if length(maybe_gcx_channel) == 1 and gcx_live? and hd(maybe_gcx_channel).status == "live" do
      hd(maybe_gcx_channel)
    else
      random_channel
    end
  end

  defp get_stream_thumbnail(%Glimesh.Streams.Channel{} = channel) do
    case channel.stream do
      %Glimesh.Streams.Stream{} = stream ->
        Glimesh.StreamThumbnail.url({stream.thumbnail, stream}, :original)

      _ ->
        Glimesh.ChannelPoster.url({channel.poster, channel}, :original)
    end
  end

  defp get_stream_thumbnail(nil), do: nil

  defp get_cached_channels do
    Glimesh.QueryCache.get_and_store!("GlimeshWeb.HomepageLive.get_cached_channels()", fn ->
      {:ok, Glimesh.Homepage.get_homepage()}
    end)
  end

  defp get_random_channel(channels) when length(channels) > 0 do
    Glimesh.QueryCache.get_and_store!("GlimeshWeb.HomepageLive.get_random_channel()", fn ->
      {:ok, Enum.random(channels)}
    end)
  end

  defp get_random_channel(_), do: nil

  @impl Phoenix.LiveView
  def handle_info({:debug, _, _}, socket) do
    # Ignore any debug messages from the video player
    {:noreply, socket}
  end
end
