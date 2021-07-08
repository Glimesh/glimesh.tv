defmodule GlimeshWeb.SupportModal do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => nil} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    channel = Glimesh.ChannelLookups.get_channel_for_user(streamer)
    can_receive_payments = Accounts.can_receive_payments?(streamer)

    {:ok,
     socket
     |> assign(:show_modal, false)
     |> assign(:site_theme, session["site_theme"])
     |> assign(:streamer, streamer)
     |> assign(:channel, channel)
     |> assign(:can_receive_payments, can_receive_payments)
     |> assign(:is_the_streamer, false)
     # Easy fallback for now
     |> assign(:tab, default_tab(can_receive_payments, channel.streamloots_url))
     |> assign(:user, nil)}
  end

  @impl true
  def mount(_params, %{"streamer" => streamer, "user" => user} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    channel = Glimesh.ChannelLookups.get_channel_for_user(streamer)
    can_receive_payments = Accounts.can_receive_payments?(streamer)

    {:ok,
     socket
     |> assign(:show_modal, false)
     |> assign(:site_theme, session["site_theme"])
     |> assign(:is_the_streamer, streamer.id == user.id)
     |> assign(:can_receive_payments, can_receive_payments)
     # Easy fallback for now
     |> assign(:tab, default_tab(can_receive_payments, channel.streamloots_url))
     |> assign(:streamer, streamer)
     |> assign(:channel, channel)
     |> assign(:user, user)}
  end

  @impl true
  def handle_event("show_modal", _value, socket) do
    {:noreply, socket |> assign(:show_modal, true)}
  end

  @impl true
  def handle_event("hide_modal", _value, socket) do
    {:noreply, socket |> assign(:show_modal, false)}
  end

  @impl true
  def handle_event("change_tab", %{"tab" => tab}, socket) do
    {:noreply, socket |> assign(:tab, tab)}
  end

  defp default_tab(can_receive_payments, streamloots_url) do
    cond do
      can_receive_payments -> "subscription"
      !is_nil(streamloots_url) -> "streamloots"
      true -> ""
    end
  end
end
