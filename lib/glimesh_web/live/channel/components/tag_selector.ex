defmodule GlimeshWeb.Channels.Components.TagSelector do
  use GlimeshWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <div>
        <label for="combobox" class="block text-sm font-medium leading-6 text-gray-900">
          Assigned to
        </label>
        <%= @value %>
        <div class="relative mt-2">
          <input
            id="combobox"
            type="text"
            class="w-full rounded-md border-0 bg-white py-1.5 pl-3 pr-12 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
            role="combobox"
            aria-controls="options"
            aria-expanded="false"
            phx-target={@myself}
            phx-keydown="suggest"
            phx-focus={show_dropdown()}
            phx-blur={hide_dropdown()}
          />
          <button
            type="button"
            class="absolute inset-y-0 right-0 flex items-center rounded-r-md px-2 focus:outline-none"
          >
            <svg
              class="h-5 w-5 text-gray-400"
              viewBox="0 0 20 20"
              fill="currentColor"
              aria-hidden="true"
            >
              <path
                fill-rule="evenodd"
                d="M10 3a.75.75 0 01.55.24l3.25 3.5a.75.75 0 11-1.1 1.02L10 4.852 7.3 7.76a.75.75 0 01-1.1-1.02l3.25-3.5A.75.75 0 0110 3zm-3.76 9.2a.75.75 0 011.06.04l2.7 2.908 2.7-2.908a.75.75 0 111.1 1.02l-3.25 3.5a.75.75 0 01-1.1 0l-3.25-3.5a.75.75 0 01.04-1.06z"
                clip-rule="evenodd"
              />
            </svg>
          </button>

          <ul
            class="absolute z-10 mt-1 max-h-60 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm"
            id="options"
            role="listbox"
            style="display: none"
          >
            <!--
        Combobox option, manage highlight styles based on mouseenter/mouseleave and keyboard navigation.

        Active: "text-white bg-indigo-600", Not Active: "text-gray-900"
      -->
            <li
              :for={result <- @results}
              class="relative cursor-default select-none py-2 pl-3 pr-9 text-gray-900"
              id={"option-" <> result.slug}
              role="option"
              tabindex="-1"
            >
              <!-- Selected: "font-semibold" -->
              <span class="block truncate"><%= result.label %></span>
              <!--
          Checkmark, only display for selected option.

          Active: "text-white", Not Active: "text-indigo-600"
        -->
              <span class="absolute inset-y-0 right-0 flex items-center pr-4 text-indigo-600">
                <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path
                    fill-rule="evenodd"
                    d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                    clip-rule="evenodd"
                  />
                </svg>
              </span>
            </li>
            <!-- More items... -->
          </ul>
        </div>
      </div>
      <%!--
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
        "phx-keydown": "suggest",
        placeholder: @placeholder
      ) %> --%>
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
       placeholder: "Search",
       results: []
     )}
  end

  def handle_event("suggest", %{"value" => query}, socket) do
    results = socket.assigns.search_func.(query, socket)

    dbg(results)

    {:noreply, socket |> assign(results: results)}
  end

  def show_dropdown(js \\ %JS{}) do
    dbg("show")

    js
    |> JS.show(transition: "fade-in-scale", to: "#options")
  end

  def hide_dropdown(js \\ %JS{}) do
    dbg("hide")

    js
    |> JS.hide(transition: "fade-out-scale", to: "#options")
  end

  def handle_event("focus", _, socket) do
    dbg("focus")
    {:noreply, socket}
  end

  def handle_event("blur", _, socket) do
    dbg("blur")
    {:noreply, socket}
  end

  def handle_event("remove", %{"value" => value}, socket) do
    {:noreply, push_event(socket, "remove-tag", %{value: value})}
  end
end
