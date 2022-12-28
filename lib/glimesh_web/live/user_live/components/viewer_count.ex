defmodule GlimeshWeb.UserLive.Components.ViewerCount do
  use GlimeshWeb, :live_component

  @impl true
  def render(assigns) do
    assigns =
      assigns |> assign_new(:visible, fn -> true end) |> assign_new(:viewer_count, fn -> 0 end)

    ~H"""
    <button class="btn btn-danger break-all" phx-click="toggle" phx-target={@myself}>
      <%= if @visible do %>
        <span class="hidden lg:block">
          <%= gettext("%{count} Viewers", count: @viewer_count) %>
        </span>
        <span class="lg:hidden">
          <%= gettext("%{count} ", count: @viewer_count) %><i class="far fa-eye"></i>
        </span>
      <% else %>
        <i class="far fa-eye-slash"></i>
      <% end %>
    </button>
    """
  end

  @impl true
  def handle_event("toggle", %{}, socket) do
    {:noreply, assign(socket, :visible, flip_visible(socket.assigns))}
  end

  defp flip_visible(%{visible: visible}), do: !visible
  defp flip_visible(_), do: false
end
