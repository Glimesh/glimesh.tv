defmodule GlimeshWeb.Admin.CategoryLive.Index do
  use GlimeshWeb, :live_view

  alias Glimesh.ChannelCategories
  alias Glimesh.Streams.Category

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :categories, list_categories())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> put_page_title(gettext("Edit Category"))
    |> assign(:category, ChannelCategories.get_category_by_id!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> put_page_title(gettext("New Category"))
    |> assign(:category, %Category{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> put_page_title(gettext("Listing Categories"))
    |> assign(:category, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category = ChannelCategories.get_category_by_id!(id)
    {:ok, _} = ChannelCategories.delete_category(category)

    {:noreply, assign(socket, :categories, list_categories())}
  end

  defp list_categories do
    ChannelCategories.list_categories()
  end
end
