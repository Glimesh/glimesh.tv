defmodule GlimeshWeb.StreamsLive.Index do
  use GlimeshWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="container">
      <h1 class="text-center mt-4 mb-4"><%= gettext("Categories") %></h1>
      <div class="row">
        <div class="col-4">
          <%= live_redirect class: "btn btn-primary btn-lg btn-block", to: ~p"/streams/gaming" do %>
            <i class="fas fa-gamepad fa-2x fa-fw"></i>
            <br />
            <small><%= gettext("Gaming") %></small>
          <% end %>
        </div>
        <div class="col-4">
          <%= live_redirect class: "btn btn-primary btn-lg btn-block", to: ~p"/streams/art" do %>
            <i class="fas fa-palette fa-2x fa-fw"></i>
            <br />
            <small><%= gettext("Art") %></small>
          <% end %>
        </div>
        <div class="col-4">
          <%= live_redirect class: "btn btn-primary btn-lg btn-block", to: ~p"/streams/music" do %>
            <i class="fas fa-headphones fa-2x fa-fw"></i>
            <br />
            <small><%= gettext("Music") %></small>
          <% end %>
        </div>
        <div class="w-100 mb-4"></div>
        <div class="col-4">
          <%= live_redirect class: "btn btn-primary btn-lg btn-block", to: ~p"/streams/tech" do %>
            <i class="fas fa-microchip fa-2x fa-fw"></i>
            <br />
            <small><%= gettext("Tech") %></small>
          <% end %>
        </div>
        <div class="col-4">
          <%= live_redirect class: "btn btn-primary btn-lg btn-block", to: ~p"/streams/irl" do %>
            <i class="fas fa-camera-retro fa-2x fa-fw"></i>
            <br />
            <small><%= gettext("IRL") %></small>
          <% end %>
        </div>
        <div class="col-4">
          <%= live_redirect class: "btn btn-primary btn-lg btn-block", to: ~p"/streams/education" do %>
            <i class="fas fa-graduation-cap fa-2x fa-fw"></i>
            <br />
            <small><%= gettext("Education") %></small>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> put_page_title(gettext("Categories"))}
  end
end
