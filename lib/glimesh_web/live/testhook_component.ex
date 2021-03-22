defmodule GlimeshWeb.TestHookComponent do
  use GlimeshWeb, :live_component

  def render(assigns) do
    ~L"""
    <%= text_input :some_form, :some_field,
        value: "",
        class: "tagify",
        "data-category": "1",
        "data-allowed-regex": "^[A-Za-z0-9 \\:\\-]{2,18}$",
        "data-allow-edit": @allow_edit,
        "data-max-options": @max_options,
        "phx-hook": "Tagify",
        placeholder: assigns.placeholder %>
    """
  end

  def mount(socket) do
    {:ok, socket |> assign(allow_edit: false, max_options: "1", placeholder: "Hello world")}
  end

  def handle_event("suggest", %{"q" => query}, socket) when byte_size(query) <= 100 do
    category = Glimesh.ChannelCategories.get_category("gaming")
    results = Glimesh.ChannelCategories.search_for_subcategories(category, query)

    {:noreply, assign(socket, matches: results)}
  end

  # def handle_event("select", %{"q" => query}, socket) when byte_size(query) <= 100 do
  #   send(self(), {:search, query})
  #   {:noreply, assign(socket, query: query, result: "Searching...", loading: true, matches: [])}
  # end

  # def handle_info({:search, query}, socket) do
  #   IO.inspect(query)
  #   # {result, _} = System.cmd("dict", ["#{query}"], stderr_to_stdout: true)
  #   result = ""
  #   {:noreply, assign(socket, loading: false, result: result, matches: [])}
  # end
end
