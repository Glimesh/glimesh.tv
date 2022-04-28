defmodule GlimeshWeb.Admin.TagLive.FormComponent do
  use GlimeshWeb, :live_component

  alias Glimesh.ChannelCategories

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div>
      <.form
        let={f}
        for={@changeset}
        id="tag-form"
        phx_target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <h2><%= @title %></h2>

        <div class="form-group">
          <%= label(f, :category_id, gettext("Category")) %>
          <%= select(f, :category_id, @categories, class: "form-control") %>
          <%= error_tag(f, :category_id) %>
        </div>

        <div class="form-group">
          <%= label(f, :name) %>
          <%= text_input(f, :name, class: "form-control") %>
          <%= error_tag(f, :name) %>
        </div>

        <div class="form-group">
          <%= label(f, :count_usage) %>
          <%= number_input(f, :count_usage, class: "form-control", disabled: true) %>
          <%= error_tag(f, :count_usage) %>
        </div>

        <%= submit("Save", class: "btn btn-primary", phx_disable_with: "Saving...") %>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{tag: tag} = assigns, socket) do
    changeset = ChannelCategories.change_tag(tag)

    categories = [{"Global Tag", nil}] ++ ChannelCategories.list_categories_for_select()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(
       :categories,
       categories
     )
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("validate", %{"tag" => tag_params}, socket) do
    changeset =
      socket.assigns.tag
      |> ChannelCategories.change_tag(tag_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  def handle_event("save", %{"tag" => tag_params}, socket) do
    save_tag(socket, socket.assigns.action, tag_params)
  end

  defp save_tag(socket, :edit, tag_params) do
    case ChannelCategories.update_tag(socket.assigns.tag, tag_params) do
      {:ok, _tag} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tag updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_tag(socket, :new, tag_params) do
    case ChannelCategories.create_tag(tag_params) do
      {:ok, _tag} ->
        {:noreply,
         socket
         |> put_flash(:info, "Tag created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
