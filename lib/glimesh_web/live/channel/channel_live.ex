defmodule GlimeshWeb.Channel.ChannelLive do
  use GlimeshWeb, :live_view

  alias GlimeshWeb.Channel.Components.{
    ChannelPreview,
    ChannelTitle,
    ReportButton,
    LivePlayer
  }

  alias GlimeshWeb.Components.UserEffects
  alias GlimeshWeb.Components.Title
  alias GlimeshWeb.Channel.ChatLive

  alias Glimesh.Accounts

  defmodule UserNotFound do
    defexception message: "user not found", plug_status: 404
  end

  defmodule UserBanned do
    defexception message: "user not found", plug_status: 404
  end

  defmodule ChannelNotFound do
    defexception message: "channel not found", plug_status: 404
  end

  def mount(%{"username" => streamer_username} = params, session, socket) do
    streamer = Glimesh.ChannelLookups.get_user_for_channel(streamer_username)

    if is_nil(streamer) do
      raise UserNotFound
    end

    if streamer.is_banned do
      raise UserBanned
    end

    if is_nil(streamer.channel) do
      {:ok, socket |> redirect(to: ~p"/#{streamer_username}")}
    else
      maybe_user = Accounts.get_user_by_session_token(session["user_token"])
      some_chat_messages = Glimesh.Chat.list_initial_chat_messages(streamer.channel)

      has_some_support_option =
        length(Glimesh.Streams.list_support_tabs(streamer, streamer.channel)) > 0

      {:ok,
       socket
       |> assign(:channel, streamer.channel)
       |> assign(:streamer, streamer)
       |> assign(:user, maybe_user)
       |> assign(:prompt_mature, false)
       |> assign(:player_error, false)
       |> assign(:has_some_support_option, has_some_support_option)
       |> assign(:support_modal_tab, nil)
       |> assign(:stripe_session_id, nil)
       |> stream(:chat_messages, some_chat_messages)}
    end
  end

  def handle_params(params, uri, socket) do
    {:noreply,
     socket
     |> assign(:active_path, uri)
     |> then(fn socket -> apply_action(socket.assigns.live_action, params, socket) end)}
  end

  def apply_action(:index, _params, socket) do
    socket
  end

  def apply_action(:support, params, socket) do
    support_success_message =
      if session_id = Map.get(params, "stripe_session_id") do
        case Stripe.Session.retrieve(session_id) |> dbg() do
          {:ok, %Stripe.Session{payment_status: "paid"}} ->
            "Your purchase has completed successfully! You can close this window to get back to the stream."

          _ ->
            nil
        end
      end

    socket
    |> assign(:support_modal_tab, Map.get(params, "tab", "subscribe"))
    |> assign(:stripe_session_id, Map.get(params, "stripe_session_id"))
    |> assign(
      :support_tabs,
      Glimesh.Streams.list_support_tabs(socket.assigns.streamer, socket.assigns.channel)
    )
    |> assign(:support_success_message, support_success_message)
  end

  def handle_event("webrtc_error", _, socket) do
    {:noreply, socket}
  end
end
