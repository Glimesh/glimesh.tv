defmodule GlimeshWeb.UserLive.Components.TagSelector do
  use GlimeshWeb, :live_component

  @impl true
  def render(assigns) do
    ~L"""
    <div id="tagify" phx-update="replace">
      <%= text_input @form, @field,
        value: @existing_tags,
        class: "tagify",
        "data-category": @current_category_id,
        "data-tags": @tags,
        "phx-hook": "TagSelector",
        placeholder: gettext("Add tags to describe your stream! Limit 10.") %>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    tags = Glimesh.ChannelCategories.list_tags_for_tagify(assigns.category_id) |> Jason.encode!()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:current_category_id, assigns.category_id)
     |> assign(:existing_tags, existing_tags(assigns.form.data))
     |> assign(:tags, tags)}
  end

  defp existing_tags(%Glimesh.Streams.Channel{tags: existing}) do
    Enum.map(existing, fn tag -> tag.name end) |> Enum.join(", ")
  end

  defp existing_tags(_) do
    ""
  end
end
