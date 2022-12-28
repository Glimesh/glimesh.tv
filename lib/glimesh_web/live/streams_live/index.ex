defmodule GlimeshWeb.StreamsLive.Index do
  use GlimeshWeb, :live_view

  alias Surface.Components.LivePatch

  alias GlimeshWeb.Components.Icons
  alias GlimeshWeb.Channels.Components.ChannelPreview

  alias GlimeshWeb.Components.Lookahead

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="flex justify-between bg-gray-800 sm:hidden px-4 pb-2">
        <%= for {name, category, icon} <- list_categories() do %>
          <.link
            navigate={
              if(@category && @category.slug == category,
                do: Routes.streams_index_path(GlimeshWeb.Endpoint, :index),
                else: Routes.streams_index_path(GlimeshWeb.Endpoint, :index, category)
              )
            }
            class={
              [
                " hover:text-white text-center flex flex-col items-center",
                if(@category && @category.slug == category, do: "text-white", else: "text-slate-300")
              ]
            }
          >
            <%= icon.(%{class: "h-8 text-center"}) %>
            <small class="text-center"><%= name %></small>
          </.link>
        <% end %>
      </div>

      <div class="container mx-auto">
        <Title.h1><%= @title %></Title.h1>

        <div class="hidden sm:flex justify-between w-96 mx-auto">
          <%= for {name, category, icon} <- list_categories() do %>
            <div>
              <.link
                navigate={
                  if(@category && @category.slug == category,
                    do: Routes.streams_index_path(GlimeshWeb.Endpoint, :index),
                    else: Routes.streams_index_path(GlimeshWeb.Endpoint, :index, category)
                  )
                }
                class={
                  [
                    "text-center flex flex-col items-center",
                    if(@category && @category.slug == category, do: "text-white")
                  ]
                }
              >
                <%= icon.(%{class: "h-12"}) %>
                <small class="text-color-link"><%= name %></small>
              </.link>
            </div>
          <% end %>
        </div>
      </div>

      <div class={
        [
          "my-4",
          if(@show_filters, do: "d-block", else: "d-none d-lg-block")
        ]
      }>
        <form>
          <div class="flex justify-between">
            <div class="">
              <label for="validationCustom01">
                <%= Glimesh.ChannelCategories.get_subcategory_label(@category) %>
              </label>
              <div id="subcategoryFilter"></div>
              <p class="mb-0">
                <%= Glimesh.ChannelCategories.get_subcategory_attribution(@category) %>
              </p>
            </div>
            <div class="">
              <label for="validationCustom01"><%= gettext("Tags") %></label>
              <div id="tagify" phx-update="ignore"></div>
            </div>
            <div class="">
              <label for="validationCustom02"><%= gettext("Language") %></label>
              <%= select(:form, :language, @locales,
                value: @prefilled_language,
                class: "custom-select"
              ) %>
            </div>
            <div class="">
              <%= gettext("Showing %{count_channels} of %{total_channels} Live Channels",
                count_channels: length(@channels),
                total_channels: length(@channels)
              ) %>

              <br />

              <%= link(gettext("Remove Filters"),
                to: Routes.streams_index_path(@socket, :index),
                class: "btn btn-primary"
              ) %>
            </div>
          </div>
        </form>
      </div>

      <div class="mx-auto max-w-[2000px] px-2">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2">
          <%= for channel <- @channels do %>
            <ChannelPreview.thumbnail_and_info channel={channel} />
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(params, session, socket) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    title = Glimesh.ChannelCategories.get_subcategory_title(nil)

    {:ok,
     socket
     |> put_page_title(title)
     |> assign(show_filters: true)
     |> assign(
       title: title,
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
  def handle_params(%{"category" => category_input} = params, _url, socket) do
    category = Glimesh.ChannelCategories.get_category(category_input)
    title = Glimesh.ChannelCategories.get_subcategory_title(category)

    {:noreply,
     socket
     |> assign(:category, category)
     |> put_page_title(title)
     |> assign(:title, title)
     |> search_channels(params)}
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
        &Icons.gaming/1
      },
      {
        gettext("Art"),
        "art",
        &Icons.art/1
      },
      {
        gettext("Music"),
        "music",
        &Icons.music/1
      },
      {
        gettext("Tech"),
        "tech",
        &Icons.tech/1
      },
      {
        gettext("IRL"),
        "irl",
        &Icons.irl/1
      },
      {
        gettext("Education"),
        "education",
        &Icons.education/1
      }
    ]
  end
end
