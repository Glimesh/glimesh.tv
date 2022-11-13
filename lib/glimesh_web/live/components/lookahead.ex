defmodule GlimeshWeb.Components.Lookahead do
  use GlimeshWeb, :surface_live_component

  alias Surface.Components.Form
  alias Surface.Components.Form.{Label, Field, TextInput}

  prop options, :list
  prop timeout, :integer, default: 250
  prop class, :css_class

  data matches, :list, default: []

  @impl true
  def render(assigns) do
    ~F"""
    <Field name="search">
      <div class="control">
        <TextInput keydown="suggest" opts={"phx-debounce": @timeout} />
      </div>
      {#if @matches != []}
        <div class="channel-typeahead-dropdown list-group d-block">
          {#for {key, value} <- @matches}
            <div class="list-group-item bg-primary-hover">
              {value}
            </div>
          {/for}
        </div>
      {/if}
    </Field>
    {!--
    <form :on-change="suggest" :on-submit="submit">
      <div class="w-100">
        {inspect(@options)}
        <input type="text" name="search" class={@class} phx-debounce={@timeout} autocomplete="off">
        {#if @matches != []}
          <div class="channel-typeahead-dropdown list-group">
            {#for match <- @matches}
              <div class="list-group-item bg-primary-hover">
                {match}
              </div>
            {/for}
          </div>
        {/if}
      </div>
    </form>
    --}
    """
  end

  @impl true
  def handle_event("suggest", %{"value" => search}, socket) do
    {:noreply, socket |> assign(matches: socket.assigns.options)}
  end

  def handle_event("submit", params, socket) do
    IO.inspect(params, label: "submit")
    {:noreply, socket |> assign(matches: [])}
  end
end
