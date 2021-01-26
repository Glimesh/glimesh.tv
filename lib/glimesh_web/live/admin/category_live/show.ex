defmodule GlimeshWeb.Admin.CategoryLive.Show do
  use GlimeshWeb, :live_view

  alias Glimesh.ChannelCategories

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> put_page_title(page_title(socket.assigns.live_action))
     |> assign(:category, ChannelCategories.get_category_by_id!(id))}
  end

  defp page_title(:show), do: gettext("Show Category")
  defp page_title(:edit), do: gettext("Edit Category")
end
