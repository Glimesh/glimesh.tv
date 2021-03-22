defmodule GlimeshWeb.UserSettings.Components.ChannelSettingsLive do
  use GlimeshWeb, :live_view

  alias Glimesh.ChannelCategories
  alias Glimesh.Streams

  @impl true
  def mount(_params, %{"channel" => channel} = session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> put_flash(:info, nil)
     |> put_flash(:error, nil)
     |> assign(:stream_key, Streams.get_stream_key(channel))
     |> assign(:channel_changeset, session["channel_changeset"])
     |> assign(:categories, session["categories"])
     |> assign(:channel, channel)
     |> assign(:category, channel.category)
     |> assign(
       :subcategory_label,
       ChannelCategories.get_subcategory_label(channel.category)
     )
     |> assign(
       :subcategory_placeholder,
       ChannelCategories.get_subcategory_select_label_description(channel.category)
     )
     |> assign(
       :existing_subcategory,
       if(channel.subcategory, do: channel.subcategory.name, else: "")
     )
     |> assign(:existing_tags, Enum.map(channel.tags, fn tag -> tag.name end) |> Enum.join(", "))
     |> assign(:route, session["route"])
     |> assign(:user, session["user"])
     |> assign(:delete_route, session["delete_route"])
     |> assign(:channel_delete_disabled, session["channel_delete_disabled"])}
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
     |> assign(:category, category)
     |> assign(
       :subcategory_label,
       ChannelCategories.get_subcategory_label(category)
     )
     |> assign(
       :subcategory_placeholder,
       ChannelCategories.get_subcategory_select_label_description(category)
     )
     |> assign(:existing_subcategory, "")
     |> assign(:existing_tags, "")
     |> assign(:current_category_id, channel["category_id"])}
  end

  def handle_event("change_channel", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("rotate_stream_key", _params, socket) do
    with :ok <-
           Bodyguard.permit(
             Streams,
             :update_channel,
             socket.assigns.channel.user,
             socket.assigns.channel
           ) do
      case Streams.rotate_stream_key(socket.assigns.channel.user, socket.assigns.channel) do
        {:ok, channel} ->
          {:noreply,
           socket
           |> put_flash(:info, "Stream key reset")
           |> assign(:stream_key, Streams.get_stream_key(channel))
           |> assign(:channel_changeset, Streams.Channel.changeset(channel))}

        {:error, _changeset} ->
          {:noreply, socket}
      end
    end
  end

  def search_categories(query, socket) do
    ChannelCategories.tagify_search_for_subcategories(socket.assigns.category, query)
  end

  def search_tags(query, socket) do
    ChannelCategories.tagify_search_for_tags(socket.assigns.category, query)
  end
end
