defmodule GlimeshWeb.Admin.CategoryLive.FormComponent do
  use GlimeshWeb, :live_component

  alias Glimesh.ChannelCategories

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
      <div>
        <.form let={f} for={@changeset} id="category-form" multipart={true} class="category-form" phx_target={@myself}
        phx-change="validate" phx-submit="save">
          <h2><%= @title %></h2>

          <div class="form-group">
            <%= label f, :name %>
            <%= text_input f, :name, class: "form-control" %>
            <%= error_tag f, :name %>
          </div>

          <div class="form-group">
            <%= label f, :slug %>
            <%= text_input f, :slug, class: "form-control", disabled: true %>
            <%= error_tag f, :slug %>
          </div>

          <%= submit "Save", class: "btn btn-primary", phx_disable_with: "Saving..." %>
        </.form>
      </div>
    """
  end

  @impl true
  def update(%{category: category} = assigns, socket) do
    changeset = ChannelCategories.change_category(category)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       :existing_categories,
       ChannelCategories.list_categories_for_select()
     )
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"category" => category_params}, socket) do
    changeset =
      socket.assigns.category
      |> ChannelCategories.change_category(category_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"category" => category_params}, socket) do
    save_category(socket, socket.assigns.action, category_params)
  end

  defp save_category(socket, :edit, category_params) do
    case ChannelCategories.update_category(socket.assigns.category, category_params) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Category updated successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_category(socket, :new, category_params) do
    case ChannelCategories.create_category(category_params) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, gettext("Category created successfully"))
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
