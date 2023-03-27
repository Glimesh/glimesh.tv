defmodule GlimeshWeb.TagifyComponent do
  use GlimeshWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <%= text_input(@form, @field,
        id: @id,
        value: @value,
        class: "tagify",
        "data-suggestions-event": "suggestions-#{@id}",
        "data-category": @category.id,
        "data-create-regex": @create_regex,
        "data-allow-edit": @allow_edit,
        "data-max-options": @max_options,
        "phx-target": @myself,
        "phx-hook": "Tagify",
        placeholder: @placeholder
      ) %>
    </div>
    """
  end

  def mount(socket) do
    {:ok,
     socket
     |> assign(
       value: "",
       allow_edit: "false",
       create_regex: "^[A-Za-z0-9: -]{2,18}$",
       max_options: "1",
       placeholder: "Search"
     )}
  end

  def handle_event("suggest", %{"value" => query}, socket) do
    results = socket.assigns.search_func.(query, socket)

    {:noreply,
     push_event(socket, "suggestions-#{socket.assigns.id}", %{value: query, results: results})}
  end

  def handle_event("remove", %{"value" => value}, socket) do
    {:noreply, push_event(socket, "remove-tag", %{value: value})}
  end
end
