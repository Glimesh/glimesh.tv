defmodule GlimeshWeb.UserLive.Components.SubcategorySelector do
  use GlimeshWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
    <div id="tagify" phx-update="replace">
      <%= text_input @form, @field,
        value: @existing_subcategory,
        class: "tagify",
        "data-category": assigns.category_id,
        "data-tags": @tags,
        "data-allowed-regex": "^[A-Za-z0-9' \\:\\-\\+\\(\\)]{2,48}$",
        "data-max-tags": "1",
        "phx-hook": "TagSelector",
        "phx-target": @myself,
        placeholder: assigns.placeholder %>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    tags = Glimesh.ChannelCategories.list_subcategories_for_tagify(assigns.category_id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:current_category_id, assigns.category_id)
     |> assign(:existing_subcategory, existing_subcategory(assigns.form.data))
     |> assign(:tags, tags)}
  end

  defp existing_subcategory(%Glimesh.Streams.Channel{subcategory: subcategory}) do
    if subcategory do
      subcategory.name
    else
      ""
    end
  end

  defp existing_subcategory(_) do
    ""
  end
end
