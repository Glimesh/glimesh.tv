defmodule GlimeshWeb.StreamsLive.List do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.ChannelCategories
  alias Glimesh.Streams

  @impl true
  def mount(%{"category" => "following"}, session, socket) do
    case Accounts.get_user_by_session_token(session["user_token"]) do
      %Glimesh.Accounts.User{} = user ->
        if session["locale"], do: Gettext.put_locale(session["locale"])

        {:ok,
         socket
         |> put_page_title(gettext("Followed Streams"))
         |> assign(:current_user, user)
         |> assign(:tag_list, nil)
         |> assign(:list_name, "Followed")}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  @impl true
  def mount(params, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    case ChannelCategories.get_category(Map.get(params, "category", nil)) do
      %Streams.Category{} = category ->
        live_tags = ChannelCategories.list_live_tags(category.id)
        subcategories = ChannelCategories.list_subcategories(category.id)

        tags_and_slugs =
          Enum.reduce(live_tags, %{}, fn tag, acc ->
            Map.put(acc, tag.slug, tag.name)
          end)

        subcategories_and_slugs =
          Enum.reduce(subcategories, %{}, fn subcategory, acc ->
            Map.put(acc, subcategory.slug, subcategory.name)
          end)

        tag_list =
          live_tags |> ChannelCategories.convert_tags_for_tagify(false) |> Jason.encode!()

        subcategory_list =
          subcategories
          |> Glimesh.ChannelCategories.convert_subcategories_for_tagify()
          |> Jason.encode!()

        locales = ["Any Language": ""] ++ Application.get_env(:glimesh, :locales)

        {:ok,
         socket
         |> put_page_title(category.name)
         |> assign(:list_name, category.name)
         |> assign(:locales, locales)
         |> assign(:tags_and_slugs, tags_and_slugs)
         |> assign(:subcategories_and_slugs, subcategories_and_slugs)
         |> assign(:tag_list, tag_list)
         |> assign(:subcategory_list, subcategory_list)
         |> assign(:tag_selected, Map.has_key?(params, "tag"))
         |> assign(:category, category)}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    channels = Glimesh.ChannelLookups.search_live_channels(params)

    blocks =
      if Map.has_key?(params, "subcategory") do
        Glimesh.Streams.Organizer.organize(channels, limit: 6, group_by: :subcategory)
      else
        Glimesh.Streams.Organizer.organize(channels)
      end

    shown_channels = Enum.sum(Enum.map(blocks, fn x -> length(x.channels) end))

    total_channels =
      Enum.sum(Enum.map(blocks, fn x -> length(x.all_channels) |> IO.inspect() end))

    prefilled_tags =
      if tags = Map.get(params, "tags") do
        Enum.map(tags, &Map.get(socket.assigns.tags_and_slugs, &1)) |> Enum.join(", ")
      else
        ""
      end

    prefilled_subcategory =
      if tags = Map.get(params, "subcategory") do
        Enum.map(tags, &Map.get(socket.assigns.subcategories_and_slugs, &1)) |> Enum.join(", ")
      else
        ""
      end

    prefilled_language = Map.get(params, "language", "Any Language")

    {:noreply,
     socket
     |> assign(:blocks, blocks)
     |> assign(:prefilled_tags, prefilled_tags)
     |> assign(:prefilled_subcategory, prefilled_subcategory)
     |> assign(:prefilled_language, prefilled_language)
     |> assign(:shown_channels, shown_channels)
     |> assign(:total_channels, total_channels)
     |> assign(:channels, channels)}
  end

  @impl true
  def handle_event("filter_change", %{"form" => form_data}, socket) do
    params =
      []
      |> append_json_param(:tags, Map.get(form_data, "tag_search"))
      |> append_json_param(:subcategory, Map.get(form_data, "subcategory_search"))
      |> append_param(:language, Map.get(form_data, "language"))

    {:noreply,
     socket
     |> push_patch(
       to: Routes.streams_list_path(socket, :index, socket.assigns.category.slug, params)
     )}
  end

  def handle_event("filter_tags", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("show_more_streams", %{"index" => index}, socket) do
    new_blocks =
      List.update_at(socket.assigns.blocks, String.to_integer(index), fn block ->
        block
        |> Map.put(:channels, block.all_channels)
        |> Map.put(:all_channels, [])
      end)

    {:noreply,
     socket
     |> assign(:blocks, new_blocks)
     |> assign(:shown_channels, Enum.sum(Enum.map(new_blocks, fn x -> length(x.channels) end)))}
  end

  defp append_json_param(list, kw, values) do
    case Jason.decode(values) do
      {:ok, decoded} -> [{kw, Enum.map(decoded, fn x -> x["slug"] end)} | list]
      {:error, _} -> list
    end
  end

  defp append_param(list, kw, value) do
    if !is_nil(value) and value != "" do
      [{kw, value} | list]
    else
      list
    end
  end
end
