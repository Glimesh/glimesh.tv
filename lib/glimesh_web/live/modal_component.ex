defmodule GlimeshWeb.ModalComponent do
  use GlimeshWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class="live-modal"
      phx-capture-click="close"
      phx-window-keydown="close"
      phx-key="escape"
      phx-target={"##{@id}"}
      phx-page-loading
    >
      <div class="modal-dialog" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <%= if @title != nil do %>
              <h5 class="modal-title">
                <%= @title %>
              </h5>
            <% end %>
            <%= live_patch(raw("&times;"), to: @return_to, class: "close") %>
          </div>
          <div class="modal-body">
            <%= live_component(@component, @opts) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.return_to)}
  end
end
