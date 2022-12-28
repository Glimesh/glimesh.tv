defmodule GlimeshWeb.Components.Title do
  use GlimeshWeb, :component

  slot :inner_block

  def h1(assigns) do
    ~H"""
    <h1 class="font-light leading-tight text-5xl mt-0 mb-2">
      <%= render_slot(@inner_block) %>
    </h1>
    """
  end

  slot :inner_block

  def h2(assigns) do
    ~H"""
    <h2 class="font-light leading-tight text-4xl mt-0 mb-2">
      <%= render_slot(@inner_block) %>
    </h2>
    """
  end

  slot :inner_block

  def h3(assigns) do
    ~H"""
    <h3 class="font-light leading-tight text-3xl mt-0 mb-2">
      <%= render_slot(@inner_block) %>
    </h3>
    """
  end
end
