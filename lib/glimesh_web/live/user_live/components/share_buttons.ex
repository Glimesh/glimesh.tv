defmodule GlimeshWeb.UserLive.Components.ShareButtons do
  use GlimeshWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @show_share do %>
      <div
        id="shareModal"
        class="live-modal"
        phx-capture-click="hide_modal"
        phx-window-keydown="hide_modal"
        phx-key="escape"
        phx-page-loading
      >
        <div class="modal-dialog modal-lg" role="document">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title">
                <%= gettext("Spread the enjoyment of %{displayname}'s community!",
                  displayname: @streamer_displayname
                ) %>
              </h5>
              <button type="button" class="close" phx-click="hide_modal" aria-label="Close">
                <span aria-hidden="true">&times;</span>
              </button>
            </div>

            <div class="modal-body">
              <p>
                <%= gettext(
                  "Share this channel and the Glimesh community with your friends!  Use the buttons below for the popular platforms or you can click 'Copy Stream URL' to post on platforms not listed."
                ) %>
              </p>
              <div class="row ml-2 mr-2 mb-4">
                <a
                  href={
                    "https://twitter.com/intent/tweet?text=#{@share_text}%0D%0A#{@share_encoded_url}"
                  }
                  target="_blank"
                  class="btn btn-primary mr-2"
                  data-size="large"
                >
                  <%= gettext("Twitter") %>
                </a>
                <a
                  href={"https://reddit.com/submit?title=#{@share_text}&url=#{@share_encoded_url}"}
                  target="_blank"
                  class="btn btn-primary"
                >
                  <%= gettext("Reddit") %>
                </a>
              </div>
              <div class="row ml-2 mr-2 mb-4">
                <div class="input-group">
                  <input
                    id="mastodon-instance-field"
                    type="text"
                    name="instance"
                    value=""
                    class="form-control"
                    placeholder={gettext("https://mastodon.social/")}
                  />
                  <button
                    id="mastodon-share-button"
                    type="button"
                    class="btn btn-primary"
                    phx-hook="MastodonShareButton"
                    data-share-url={"#{@share_encoded_url}"}
                    data-share-text={"#{@share_text}"}
                    data-instance-selector="#mastodon-instance-field"
                  >
                    <%= gettext("Mastodon") %>
                  </button>
                </div>
              </div>
              <div class="row ml-2 mr-2">
                <div class="input-group">
                  <input type="text" class="form-control" value={"#{@share_url}"} />
                  <a
                    href="#"
                    id="share-copy-url-button"
                    class="btn btn-primary"
                    phx-hook="ClickToCopy"
                    data-copy-value={"#{@share_url}"}
                    data-copied-error-text={gettext("Error")}
                    data-copied-text={gettext("Copied to Clipboard")}
                  >
                    <%= gettext("Copy Stream URL") %>
                  </a>
                </div>
              </div>
            </div>

            <div class="modal-footer">
              <button class="btn btn-primary float-right" phx-click="hide_modal" aria-label="Close">
                <%= gettext("Close") %>
              </button>
            </div>
          </div>
        </div>
      </div>
    <% end %>
    """
  end

  @impl true
  def mount(
        _params,
        %{
          "streamer_username" => username,
          "streamer_displayname" => displayname,
          "share_text" => share_text
        },
        socket
      ) do
    share_url =
      "https://glimesh.tv" <>
        Routes.user_stream_path(socket, :index, username) <> "?follow_host=false"

    share_encoded_url = URI.encode_www_form(share_url)

    {:ok,
     socket
     |> assign(:streamer_displayname, displayname)
     |> assign(:share_text, share_text)
     |> assign(:share_encoded_url, share_encoded_url)
     |> assign(:share_url, share_url)
     |> assign(:show_share, false)}
  end

  @impl true
  def handle_event("show_modal", _value, socket) do
    {:noreply, socket |> assign(:show_share, true)}
  end

  @impl true
  def handle_event("hide_modal", _value, socket) do
    {:noreply, socket |> assign(:show_share, false)}
  end
end
