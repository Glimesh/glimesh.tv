defmodule GlimeshWeb.StreamsLive.List do
  use GlimeshWeb, :live_view

  alias Glimesh.Accounts
  alias Glimesh.ChannelCategories
  alias Glimesh.ChannelLookups
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
         |> assign(:category_background_url, "")
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

        tags_and_slugs =
          Enum.reduce(live_tags, %{}, fn tag, acc ->
            Map.put(acc, tag.slug, tag.name)
          end)

        tag_list = live_tags |> ChannelCategories.convert_tags_for_tagify(false)
        locales = ["Any Language": "Any Language"] ++ Application.get_env(:glimesh, :locales)

        {:ok,
         socket
         |> put_page_title(category.name)
         |> assign(:list_name, category.name)
         |> assign(:locales, locales)
         |> assign(:tags_and_slugs, tags_and_slugs)
         |> assign(:tag_list, tag_list)
         |> assign(:tag_selected, Map.has_key?(params, "tag"))
         |> assign(:category_background_url, category_background_url(category.slug))
         |> assign(:category, category)}

      nil ->
        {:ok, redirect(socket, to: "/")}
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    channels =
      if Map.get(params, "category") == "following" do
        ChannelLookups.list_live_followed_channels(socket.assigns.current_user)
      else
        ChannelLookups.filter_live_channels(Map.take(params, ["category"]))
      end

    prefilled_tags =
      if tags = Map.get(params, "tags") do
        Enum.map(tags, &Map.get(socket.assigns.tags_and_slugs, &1)) |> Enum.join(", ")
      else
        ""
      end

    # prefilled_language = Map.get(params, "language", "Any Language")

    {:noreply,
     socket
     |> assign(:prefilled_tags, prefilled_tags)
     #  |> assign(:prefilled_language, prefilled_language)
     |> assign(:original_channels, channels)
     |> filter_tags(Map.get(params, "tags", []))}
  end

  @impl true
  def handle_event("filter_tags", params, socket) do
    tags = Enum.map(params, fn x -> x["slug"] end)

    {:noreply,
     push_patch(socket,
       to: Routes.streams_list_path(socket, :index, socket.assigns.category.slug, tags: tags)
     )}
  end

  # def handle_event("filter_language", params, socket) do
  #   IO.inspect(params, label: "filter_language")

  #   {:noreply, socket |> filter_language("English")}
  # end

  defp filter_tags(socket, []) do
    socket |> assign(:visible_channels, socket.assigns.original_channels)
  end

  defp filter_tags(socket, list_of_tags) do
    channels =
      Enum.filter(socket.assigns.original_channels, fn channel ->
        channel_tags = Enum.map(channel.tags, fn t -> t.slug end)

        Enum.any?(channel_tags, fn x -> x in list_of_tags end)
      end)

    if length(channels) > 0 do
      socket |> assign(:visible_channels, channels)
    else
      # No streams, either bad tags or old tags
      socket
      |> push_patch(to: Routes.streams_list_path(socket, :index, socket.assigns.category.slug))
    end
  end

  # defp filter_language(socket, "Any Language") do
  #   socket |> assign(:visible_channels, socket.assigns.original_channels)
  # end

  # defp filter_language(socket, locale) do
  #   channels =
  #     Enum.filter(socket.assigns.original_channels, fn channel ->
  #       channel.language == locale
  #     end)

  #   if length(channels) > 0 do
  #     socket |> assign(:visible_channels, channels)
  #   else
  #     # No streams, probably bad lang or no live channels anymore
  #     socket
  #     |> push_patch(to: Routes.streams_list_path(socket, :index, socket.assigns.category.slug))
  #   end
  # end

  defp category_background_url(slug) do
    image =
      case slug do
        "gaming" -> "/images/homepage/bg-gaming.jpg"
        "art" -> "/images/homepage/bg-art.jpg"
        "music" -> "/images/homepage/bg-music.jpg"
        "tech" -> "/images/homepage/bg-tech.jpg"
        "irl" -> "/images/homepage/bg-irl.jpg"
        "education" -> "/images/homepage/bg-education.jpg"
      end

    Routes.static_path(GlimeshWeb.Endpoint, image)
  end
end
