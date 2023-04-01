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

      {:ok,
       socket
       |> assign(channel: streamer.channel)
       |> assign(streamer: streamer)
       |> assign(user: maybe_user)
       |> assign(prompt_mature: false)
       |> assign(player_error: false)
       |> stream(:chat_messages, some_chat_messages)}
    end
  end
end
