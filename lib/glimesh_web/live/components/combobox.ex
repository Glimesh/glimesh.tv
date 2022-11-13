defmodule GlimeshWeb.Components.ComboboxOption do
  @enforce_keys [:key, :value]
  defstruct [:key, :value, :extra]

  @type t() :: %__MODULE__{
          key: String.t(),
          value: String.t(),
          extra: any()
        }

  @spec new(String.t(), String.t(), any()) :: t()
  def new(key, value, extra \\ nil) when is_binary(value) do
    %__MODULE__{key: key, value: value, extra: extra}
  end
end

defmodule GlimeshWeb.Components.Combobox do
  @moduledoc ~S"""
  Comboxbox is a searchable select field.

  On selection the value is stored in a text field hidden from view which should trigger the outer form's "change" event.

  Example 1:

    <Combobox id="colors1" options={for color <- ["Red", "Green", "Blue"], do: ComboboxOption.new(color, color)}/>

  Example 2:

    <Combobox id="colors2" options={for color <- ["Red", "Green", "Blue"], do: ComboboxOption.new(color, color)}>
      <:option :let={option: option>
        <div class="p-2" style={"background: #{option.key}}"}>{option.value}/div>
      </:option>

      <:no_options>
        <div class="p-2">No colors</div>
      </:no_options>
    </Combobox>
  """
  use Surface.LiveComponent

  alias GlimeshWeb.Components.ComboboxOption
  alias Phoenix.LiveView.JS

  @doc "An identifier for the form"
  prop form, :form, from_context: {Surface.Components.Form, :form}

  @doc "An identifier for the input"
  prop field, :any, from_context: {Surface.Components.Form.Field, :field}

  @doc "Placeholder for search input. Set to empty string to disable."
  prop placeholder, :string

  @doc "Options"
  prop options, :list, default: []

  @doc "Option slot"
  slot option, arg: %{item: ComboboxOption, index: :integer, active_index: :integer}

  @doc "No options slot"
  slot no_options

  @doc "Extra JS command to execute on selected"
  prop on_selected, :event, default: %JS{}

  data filtered_options, :list

  data search_input_id, :string

  data search_input_value, :string, default: ""

  data hidden_input_name, :string

  data hidden_input_value, :any

  data active_index, :integer

  def update(assigns, socket) do
    placeholder =
      if(placeholder = assigns[:placeholder],
        do: placeholder,
        else: Phoenix.HTML.Form.humanize(assigns.field)
      )

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(
        search_input_id: Phoenix.HTML.Form.input_id(assigns.form, assigns.field),
        hidden_input_value: Phoenix.HTML.Form.input_value(assigns.form, assigns.field),
        hidden_input_name: Phoenix.HTML.Form.input_name(assigns.form, assigns.field),
        placeholder: placeholder,
        filtered_options: assigns.options,
        active_index: 0
      )
    }
  end

  def render(assigns) do
    ~F"""
    <div
      id={@id}
      :hook="Combobox"
      :on-click-away={close(@id)}
      :on-window-keydown={close(@id)}
      phx-key="escape"
      class="relative"
      data-active-index={@active_index}
      data-open="false"
      data-on-open={open(@id)}
      data-on-up={JS.push("navigate", value: %{key: "ArrowUp"}, target: "##{@id}")}
      data-on-down={JS.push("navigate", value: %{key: "ArrowDown"}, target: "##{@id}")}
      data-on-selected={@on_selected |> JS.dispatch("change", to: "##{@id} [data-hidden-input]")}
    >
      <input
        :on-change={open(@id)}
        id={@search_input_id}
        data-search-input
        value={@search_input_value}
        placeholder={@placeholder}
        type="text"
        class="browser-default border outline-none p-3 rounded w-full"
      />
      <ul
        id={"#{@id}-dropdown"}
        data-dropdown
        class="position-absolute z-10 bg-white w-full rounded border shadow overflow-auto max-h-60 snap-mandatory snap-y"
      >
        {#for {%ComboboxOption{} = option, index} <- Enum.with_index(@filtered_options)}
          <li :on-click={close(@id) |> select(@id, option.key)} class="snap-start">
            <#slot {@option, option: option, index: index, active_index: @active_index}>
              <div class={
                "hover:cursor-pointer hover:bg-gray-300 p-2 text-dark",
                "bg-gray-400 hover:!bg-gray-400": index == @active_index
              }>
                {option.value}
              </div>
            </#slot>
          </li>
        {#else}
          <li>
            <#slot {@no_options}>
              <div class="p-2">No results</div>
            </#slot>
          </li>
        {/for}
      </ul>
      <input
        data-hidden-input
        type="text"
        name={@hidden_input_name}
        value={@hidden_input_value}
        class="d-none"
      />
      {!-- type="hidden" does not trigger change events so hidden with CSS instead. --}
    </div>
    """
  end

  def handle_event("search", %{"value" => value}, socket) do
    filtered_options = filter_options(socket.assigns.options, value)
    {:noreply, assign(socket, filtered_options: filtered_options, active_index: 0)}
  end

  def handle_event("select", %{"key" => key}, socket) do
    {
      :noreply,
      socket
      |> assign(
        search_input_value: get_option_value(socket.assigns.options, key),
        hidden_input_value: key,
        active_index: 0
      )
      |> push_event("combobox:selected:#{socket.assigns.id}", %{})
    }
  end

  def handle_event("navigate", %{"key" => "ArrowUp"}, socket) do
    active_index = max(socket.assigns.active_index - 1, 0)
    {:noreply, assign(socket, active_index: active_index)}
  end

  def handle_event("navigate", %{"key" => "ArrowDown"}, socket) do
    active_index =
      min(socket.assigns.active_index + 1, Enum.count(socket.assigns.filtered_options) - 1)

    {:noreply, assign(socket, active_index: active_index)}
  end

  def handle_event("navigate", params, socket) do
    {:noreply, socket}
  end

  defp filter_options(options, search) when is_list(options) and is_binary(search) do
    Enum.filter(options, fn %ComboboxOption{} = option ->
      String.contains?(String.downcase(option.value), String.downcase(search))
    end)
  end

  defp get_option_value(options, key, default \\ "") when is_list(options) do
    Enum.reduce_while(options, default, fn %ComboboxOption{} = option, _acc ->
      if option.key == key do
        {:halt, option.value}
      else
        {:cont, default}
      end
    end)
  end

  defp open(js \\ %JS{}, id) do
    js
    |> JS.set_attribute({"data-open", true}, to: "#" <> id)
  end

  defp close(js \\ %JS{}, id) do
    js
    |> JS.set_attribute({"data-open", false}, to: "#" <> id)
  end

  defp select(js \\ %JS{}, id, key) do
    js
    |> JS.push("select", value: %{key: key})
  end
end
