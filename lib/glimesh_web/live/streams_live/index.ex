defmodule GlimeshWeb.StreamsLive.Index do
  use GlimeshWeb, :surface_live_view

  alias Surface.Components.LivePatch

  alias GlimeshWeb.Channels.Components.ChannelPreview

  alias GlimeshWeb.Components.Lookahead

  @impl true
  def render(assigns) do
    ~F"""
    <div>
      <div class="container">
        <h1 class="text-center mt-4 mb-4">{gettext("Browse Live Streams")}</h1>

        <div class="row row-cols-3 row-cols-md-6 mb-4">
          {#for {name, category, icon} <- list_categories()}
            <div class="col">
              <LivePatch
                to={if category == @category,
                  do: Routes.streams_index_path(GlimeshWeb.Endpoint, :index),
                  else: Routes.streams_index_path(GlimeshWeb.Endpoint, :index, category)}
                class={"btn btn-outline-primary btn-lg btn-block", "btn-primary text-white": category == @category}
              >
                <i class={"fas fa-fw", icon} />
                <small class="text-color-link">{name}</small>
              </LivePatch>
            </div>
          {/for}
        </div>
      </div>

      <div class={[
        "container container-stream-filters mb-4",
        if(@show_filters, do: "d-block", else: "d-none d-lg-block")
      ]}>
        <form>
          <div class="row">
            <div class="col-md-6 col-lg-3 mb-2">
              <label for="validationCustom01">
                {Glimesh.ChannelCategories.get_subcategory_label(@category)}
              </label>
              <div id="subcategoryFilter">
                <Lookahead id="subcategory-search" options={@subcategory_list} />
                {!--text_input(:form, :subcategory_search,
                  value: @prefilled_subcategory,
                  class: "tagify",
                  "data-tags": @subcategory_list,
                  "phx-hook": "TagSearch",
                  placeholder: Glimesh.ChannelCategories.get_subcategory_search_label_description(@category)
                )--}
              </div>
              <p class="mb-0">
                {Glimesh.ChannelCategories.get_subcategory_attribution(@category)}
              </p>
            </div>
            <div class="col-md-6 col-lg-3 mb-2">
              <label for="validationCustom01">{gettext("Tags")}</label>
              <div id="tagify" phx-update="ignore">
                {!--text_input(:form, :tag_search,
                  value: @prefilled_tags,
                  class: "tagify",
                  "data-tags": @tag_list,
                  "phx-hook": "TagSearch",
                  placeholder: gettext("Search for a stream by tags")
                )--}
              </div>
            </div>
            <div class="col-md-6 col-lg-3 mb-2">
              <label for="validationCustom02">{gettext("Language")}</label>
              {select(:form, :language, @locales, value: @prefilled_language, class: "custom-select")}
            </div>
            <div class="col-md-6 col-lg-3 text-right">
              {gettext("Showing %{count_channels} of %{total_channels} Live Channels",
                count_channels: length(@channels),
                total_channels: length(@channels)
              )}

              <br>

              {link(gettext("Remove Filters"),
                to: Routes.streams_index_path(@socket, :index),
                class: "btn btn-primary"
              )}
            </div>
          </div>
        </form>
      </div>

      <div class="container container-stream-list px-lg-2">
        <div class="row row-cols-1 row-cols-md-2 row-cols-lg-3 no-gutters mx-lg-n2">
          {#for channel <- @channels}
            <div class="col py-2 px-2">
              <ChannelPreview channel={channel} />
            </div>
          {/for}
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(params, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    {:ok,
     socket
     |> put_page_title(gettext("Browse Live Streams"))
     |> assign(show_filters: true)
     |> assign(
       prefilled_subcategory: nil,
       category: nil,
       subcategory_list: [],
       prefilled_tags: nil,
       tag_list: [],
       locales: [],
       prefilled_language: nil
     )
     |> search_channels(params)}
  end

  @impl true
  def handle_params(%{"category" => category} = params, _url, socket) do
    {:noreply, socket |> assign(:category, category) |> search_channels(params)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, socket |> assign(:category, nil) |> search_channels(params)}
  end

  defp search_channels(socket, unsafe_params) do
    params = Map.take(unsafe_params, ["category"])

    channels = Glimesh.ChannelLookups.search_live_channels(params)

    live_tags =
      Glimesh.ChannelCategories.list_live_tags()
      |> Enum.map(fn tag -> {tag.id, tag.name} end)

    # |> Enum.into(%{})

    subcategories =
      Glimesh.ChannelCategories.list_live_subcategories()
      |> Enum.map(fn subcategory -> {subcategory.id, subcategory.name} end)

    # |> Enum.into(%{})

    socket
    |> assign(channels: channels, tag_list: live_tags, subcategory_list: subcategories)
  end

  defp list_categories do
    [
      {
        gettext("Gaming"),
        "gaming",
        "fa-gamepad"
      },
      {
        gettext("Art"),
        "art",
        "fa-palette"
      },
      {
        gettext("Music"),
        "music",
        "fa-headphones"
      },
      {
        gettext("Tech"),
        "tech",
        "fa-microchip"
      },
      {
        gettext("IRL"),
        "irl",
        "fa-camera-retro"
      },
      {
        gettext("Education"),
        "education",
        "fa-graduation-cap"
      }
    ]
  end
end
