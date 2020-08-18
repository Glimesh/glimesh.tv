defmodule GlimeshWeb.Admin.CategoryLive.Index do
  use GlimeshWeb, :live_view

  alias Glimesh.Streams
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
    |> assign(:page_title, "Edit Category")
    |> assign(:category, Streams.get_category_by_id!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Category")
    |> assign(:category, %Category{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Categories")
    |> assign(:category, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    category = Streams.get_category_by_id!(id)
    {:ok, _} = Streams.delete_category(category)

    {:noreply, assign(socket, :categories, list_categories())}
  end

  defp list_categories do
    Streams.list_categories()
  end
end
