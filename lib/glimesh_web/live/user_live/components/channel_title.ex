defmodule GlimeshWeb.UserLive.Components.ChannelTitle do
  use GlimeshWeb, :live_view

  alias Glimesh.ChannelCategories
  alias Glimesh.ChannelLookups
  alias Glimesh.Streams

  def render_badge(channel) do
    if channel.status == "live" do
      raw("""
      <span class="badge badge-danger">Live!</span>
      """)
    else
      raw("")
    end
  end

  @impl true
  def mount(_params, %{"channel_id" => channel_id, "user" => nil} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])
    if connected?(socket), do: Streams.subscribe_to(:channel, channel_id)
    channel = ChannelLookups.get_channel!(channel_id)

    {:ok,
     socket
     |> assign(:channel, channel)
     |> assign(:user, nil)
     |> assign(:channel, channel)
     |> assign(:editing, false)
     |> assign(:can_change, false)}
  end

  @impl true
  def mount(_params, %{"channel_id" => channel_id, "user" => user} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])
    if connected?(socket), do: Streams.subscribe_to(:channel, channel_id)
    channel = ChannelLookups.get_channel!(channel_id)

    {:ok,
     socket
     |> assign_categories()
     |> assign_subcategory(channel.category)
     |> assign_existing_tags(channel)
     |> assign(:channel, channel)
     |> assign(:user, user)
     |> assign(:channel, channel)
     |> assign(:changeset, Streams.change_channel(channel))
     |> assign(:current_category_id, channel.category_id)
     |> assign(:category, channel.category)
     |> assign(:can_change, Bodyguard.permit?(Glimesh.Streams, :update_channel, user, channel))
     |> assign(:editing, false)}
  end

  def search_categories(query, socket) do
    ChannelCategories.tagify_search_for_subcategories(socket.assigns.category, query)
  end

  def search_tags(query, socket) do
    ChannelCategories.tagify_search_for_tags(socket.assigns.category, query)
  end

  @impl true
  def handle_event("toggle-edit", _value, socket) do
    {:noreply, socket |> assign(:editing, !socket.assigns.editing)}
  end

  @impl true
  def handle_event(
        "change_channel",
        %{"_target" => ["channel", "category_id"], "channel" => channel},
        socket
      ) do
    category = ChannelCategories.get_category_by_id!(channel["category_id"])

    {:noreply,
     socket
     |> assign_subcategory(category)
     |> assign(:existing_subcategory, "")
     |> assign(:existing_tags, "")
     |> assign(:category, category)
     |> assign(:current_category_id, channel["category_id"])}
  end

  def handle_event("change_channel", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"channel" => channel}, socket) do
    case Streams.update_channel(socket.assigns.user, socket.assigns.channel, channel) do
      {:ok, channel} ->
        {:noreply,
         socket
         |> assign_subcategory(channel.category)
         |> assign_existing_tags(channel)
         |> assign(:editing, false)
         |> assign(:channel, channel)
         |> assign(:changeset, Streams.change_channel(channel))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  @impl true
  def handle_info({:channel, channel}, socket) do
    {:noreply,
     socket
     |> assign_subcategory(channel.category)
     |> assign_existing_tags(channel)
     |> assign(:editing, false)
     |> assign(:channel, channel)
     |> assign(:changeset, Streams.change_channel(channel))}
  end

  defp assign_subcategory(socket, category) do
    socket
    |> assign(
      :subcategory_label,
      ChannelCategories.get_subcategory_label(category)
    )
    |> assign(
      :subcategory_placeholder,
      ChannelCategories.get_subcategory_select_label_description(category)
    )
    |> assign(
      :subcategory_attribution,
      Glimesh.ChannelCategories.get_subcategory_attribution(category)
    )
  end

  defp assign_existing_tags(socket, channel) do
    socket
    |> assign(
      :existing_subcategory,
      if(channel.subcategory, do: channel.subcategory.name, else: "")
    )
    |> assign(:existing_tags, Enum.map(channel.tags, fn tag -> tag.name end) |> Enum.join(", "))
  end

  defp assign_categories(socket) do
    socket
    |> assign(
      :categories,
      ChannelCategories.list_categories_for_select()
    )
  end
end
