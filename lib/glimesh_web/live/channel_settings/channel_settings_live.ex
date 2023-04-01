defmodule GlimeshWeb.ChannelSettings.ChannelSettingsLive do
  use GlimeshWeb, :live_view

  alias Glimesh.ChannelCategories
  alias Glimesh.Interactive
  alias Glimesh.Streams

  @impl true
  def mount(_params, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    streamer = Glimesh.Accounts.get_user_by_session_token(session["user_token"])

    # TODO: We already have a channel, optimize these preloads

    case Glimesh.ChannelLookups.get_channel_for_user(streamer, [
           :user,
           :category,
           :subcategory,
           :tags
         ]) do
      %Glimesh.Streams.Channel{} = channel ->
        {:ok,
         socket
         |> put_page_title(gettext("Channel Settings"))
         |> assign(form: to_form(Streams.change_channel(channel, %{})))
         |> assign(:stream_key, Streams.get_stream_key(channel))
         |> assign(:channel_hours, Streams.get_channel_hours(channel))
         |> assign(:channel_changeset, Streams.change_channel(channel, %{}))
         |> assign(:categories, Glimesh.ChannelCategories.list_categories_for_select())
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
           :subcategory_attribution,
           Glimesh.ChannelCategories.get_subcategory_attribution(channel.category)
         )
         |> assign(
           :existing_subcategory,
           if(channel.subcategory, do: channel.subcategory.name, else: "")
         )
         |> assign(:existing_tags, Enum.map_join(channel.tags, ", ", fn tag -> tag.name end))
         |> assign(:user, session["user"])
         |> assign(:delete_route, session["delete_route"])
         |> assign(:channel_delete_disabled, session["channel_delete_disabled"])}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  def handle_params(_, _, socket) do
    {:noreply, socket}
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
     |> assign(
       :subcategory_attribution,
       Glimesh.ChannelCategories.get_subcategory_attribution(category)
     )
     |> assign(:existing_subcategory, "")
     |> assign(:existing_tags, "")
     |> assign(:current_category_id, channel["category_id"])}
  end

  def handle_event("change_channel", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("replace_interactive", _params, socket) do
    # This has to run before a new project is uploaded. Removes the previous project
    Enum.each(socket.assigns.channel.interactive_project || [], fn e ->
      Interactive.delete({e.file_name, socket.assigns.channel})
    end)

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
           |> put_flash(
             :info,
             "Stream key reset, make sure to update your streaming client with the new key."
           )
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