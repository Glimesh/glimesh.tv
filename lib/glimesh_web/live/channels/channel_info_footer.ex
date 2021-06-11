defmodule GlimeshWeb.Channels.ChannelInfoFooter do
  use GlimeshWeb, :live_view

  alias Glimesh.Presence
  alias Glimesh.Streams

  @impl Phoenix.LiveView
  def render(assigns) do
    # params = streamer_id, streamer_avatar, streamer_displayname, streamer_username, streamer_can_receive_payments,
    ~L"""
    <div class="card-footer p-1 d-none d-sm-block">
      <div class="row">
          <div class="col-8 d-inline-flex align-items-center">

          </div>
          <div class="col-4 align-self-center">
              <div class="float-right mr-sm-2">
                  <div class="d-inline-block mr-sm-2">
                    <%= live_render(@socket, GlimeshWeb.Channels.DebugModal, id: "debug-modal") %>
                  </div>
                  <div class="d-inline-block">
                      <%= live_render(@socket, GlimeshWeb.UserLive.Components.ReportButton, id: "report-button", session: %{"user_id_to_report" => @streamer_id}) %>
                  </div>
              </div>
          </div>
      </div>

      Debug Modal
    </div>
    """
  end

  @impl Phoenix.LiveView
  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       streamer_id: session["streamer_id"],
       streamer_username: session["streamer_username"],
       streamer_avatar: session["streamer_avatar"],
       streamer_displayname: session["streamer_displayname"],
       streamer_can_receive_payments: session["streamer_can_receive_payments"],
       streamer_color: session["streamer_color"],
       channel_language: session["channel_language"],
       channel_mature: session["channel_mature"]
     )}
  end
end
