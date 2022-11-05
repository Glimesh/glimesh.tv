defmodule GlimeshWeb.UserLive.Components.ChannelTitle do
  use GlimeshWeb, :live_view

  alias Glimesh.ChannelCategories
  alias Glimesh.ChannelLookups
  alias Glimesh.StreamModeration
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
    is_editor = StreamModeration.is_channel_editor?(user, channel)

    {:ok,
     socket
     |> assign_categories()
     |> assign(:channel, channel)
     |> assign(:user, user)
     |> assign(:channel, channel)
     |> assign(:changeset, Streams.change_channel(channel))
     |> assign(:current_category_id, channel.category_id)
     |> assign(:subcategory_label, "")
     |> assign(:subcategory_placeholder, "")
     |> assign(:subcategory_attribution, "")
     |> assign(:existing_tags, "")
     |> assign(:existing_subcategory, "")
     |> assign(:recent_subcategories, "")
     |> assign(:recent_tags, "")
     |> assign(:category, channel.category)
     |> assign(
       :can_change,
       Bodyguard.permit?(Glimesh.Streams, :edit_channel_title_and_tags, user, [channel, is_editor])
     )
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
    recent_subcategories =
      ChannelCategories.get_channel_recent_subcategories_for_category(socket.assigns.channel)

    recent_tags = ChannelCategories.get_channel_recent_tags_for_category(socket.assigns.channel)

    {:noreply,
     socket
     |> assign(:editing, !socket.assigns.editing)
     |> assign_subcategory(socket.assigns.channel.category)
     |> assign_existing_tags(socket.assigns.channel)
     |> assign(:recent_subcategories, recent_subcategories)
     |> assign(:recent_tags, recent_tags)}
  end

  @impl true
  def handle_event(
        "change_channel",
        %{"_target" => ["channel", "category_id"], "channel" => channel},
        socket
      ) do
    category = ChannelCategories.get_category_by_id!(channel["category_id"])

    recent_subcategories =
      ChannelCategories.get_channel_recent_subcategories_for_category(
        socket.assigns.channel,
        channel["category_id"]
      )

    recent_tags =
      ChannelCategories.get_channel_recent_tags_for_category(
        socket.assigns.channel,
        channel["category_id"]
      )

    socket =
      if socket.assigns.channel.category_id == category.id do
        assign_existing_tags(socket, socket.assigns.channel)
      else
        socket
        |> assign(:existing_tags, "")
        |> assign(:existing_subcategory, "")
      end

    {:noreply,
     socket
     |> assign_subcategory(category)
     |> assign(:recent_subcategories, recent_subcategories)
     |> assign(:recent_tags, recent_tags)
     |> assign(:category, category)
     |> assign(:current_category_id, channel["category_id"])}
  end

  def handle_event("change_channel", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("save", %{"channel" => channel}, socket) do
    case Streams.edit_channel_title_and_tags(socket.assigns.user, socket.assigns.channel, channel) do
      {:ok, channel} ->
        {:noreply,
         socket
         |> put_page_title(channel.title)
         |> assign_subcategory(channel.category)
         |> assign_existing_tags(channel)
         |> assign(:editing, false)
         |> assign(:channel, channel)
         |> assign(:changeset, Streams.change_title_and_tags(channel))}

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
    |> assign(
      :existing_tags,
      Enum.map_join(channel.tags, ", ", fn tag -> tag.name end)
    )
  end

  defp assign_categories(socket) do
    socket
    |> assign(
      :categories,
      ChannelCategories.list_categories_for_select()
    )
  end
end
