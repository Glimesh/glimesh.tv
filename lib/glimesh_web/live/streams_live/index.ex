defmodule GlimeshWeb.StreamsLive.Index do
  use GlimeshWeb, :live_view

  alias GlimeshWeb.Components.Icons
  alias GlimeshWeb.Channel.Components.ChannelPreview

  alias GlimeshWeb.Components.Lookahead
  alias GlimeshWeb.Components.Title

  @impl true
  def render(assigns) do
    ~H"""
    <div class="overflow-hidden rounded-lg shadow">
      <div class="m-4 divide-y divide-slate-700 lg:grid lg:grid-cols-12 lg:divide-y-0 lg:divide-x">
        <aside class="lg:col-span-2 bg-slate-800/75 space-y-4 py-4">
          <!-- Mobile -->
          <div class="flex justify-between bg-gray-800 sm:hidden px-4 pb-2">
            <%= for {name, category, icon} <- list_categories() do %>
              <.link
                navigate={
                  if(@category && @category.slug == category,
                    do: ~p"/streams",
                    else: ~p"/streams/#{category}"
                  )
                }
                class={[
                  " hover:text-white text-center flex flex-col items-center",
                  if(@category && @category.slug == category, do: "text-white", else: "text-slate-300")
                ]}
              >
                <%= icon.(%{class: "h-8 text-center"}) %>
                <small class="text-center"><%= name %></small>
              </.link>
            <% end %>
          </div>

          <div class="flex flex-col justify-between mx-auto space-y-2">
            <%= for {name, category, icon} <- list_categories() do %>
              <.link
                navigate={
                  if(@category && @category.slug == category,
                    do: ~p"/streams",
                    else: ~p"/streams/#{category}"
                  )
                }
                class={[
                  "text-center flex flex-row items-center",
                  if(@category && @category.slug == category, do: "text-white")
                ]}
              >
                <%= icon.(%{class: "w-6"}) %>
                <span class="pl-4 text-color-link"><%= name %></span>
              </.link>
            <% end %>
          </div>

          <div class="my-4">
            <%!--
          <fieldset>
            <legend class="w-full px-2">
              <!-- Expand/collapse section button -->
              <button
                type="button"
                class="flex w-full items-center justify-between p-2 "
                aria-controls="filter-section-0"
                aria-expanded="false"
              >
                <span class="text-sm font-medium">Category</span>
                <span class="ml-6 flex h-7 items-center">
                  <!--
                        Expand/collapse icon, toggle classes based on section open state.

                        Open: "-rotate-180", Closed: "rotate-0"
                      -->
                  <svg
                    class="rotate-0 h-5 w-5 transform"
                    viewBox="0 0 20 20"
                    fill="currentColor"
                    aria-hidden="true"
                  >
                    <path
                      fill-rule="evenodd"
                      d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </span>
              </button>
            </legend>
            <div class="px-4 pb-2 pt-4" id="filter-section-0">
              <div class="space-y-2">
                <div
                  :for={category <- @live_subcategories}
                  class="flex items-center p-4 bg-center bg-cover rounded-lg bg-slate-600"
                  style={[
                    "background-image: url('#{category.background_image}'); text-shadow: 0.07em 0 black, 0 0.07em black, -0.07em 0 black, 0 -0.07em black;"
                  ]}
                >
                  <input
                    id="color-0-mobile"
                    name="color[]"
                    value="white"
                    type="checkbox"
                    class="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                  />
                  <label for="color-0-mobile" class="ml-3 text-sm"><%= category.name %></label>
                </div>
              </div>
            </div>
          </fieldset>
          --%>

            <fieldset>
              <legend class="w-full px-2">
                <!-- Expand/collapse section button -->
                <button
                  type="button"
                  class="flex w-full items-center justify-between p-2 "
                  aria-controls="filter-section-0"
                  aria-expanded="false"
                >
                  <span class="text-sm font-medium">Tag</span>
                  <span class="ml-6 flex h-7 items-center">
                    <!--
                        Expand/collapse icon, toggle classes based on section open state.

                        Open: "-rotate-180", Closed: "rotate-0"
                      -->
                    <svg
                      class="rotate-0 h-5 w-5 transform"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </span>
                </button>
              </legend>
              <div class="px-4 pb-2 pt-4" id="filter-section-0">
                <div class="space-y-4">
                  <div :for={category <- @live_subcategories} class="flex items-center">
                    <input
                      id="color-0-mobile"
                      name="color[]"
                      value="white"
                      type="checkbox"
                      class="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                    />
                    <label for="color-0-mobile" class="ml-3 text-sm"><%= category.name %></label>
                  </div>
                </div>
              </div>
            </fieldset>

            <fieldset>
              <legend class="w-full px-2">
                <!-- Expand/collapse section button -->
                <button
                  type="button"
                  class="flex w-full items-center justify-between p-2 "
                  aria-controls="filter-section-0"
                  aria-expanded="false"
                >
                  <span class="text-sm font-medium">Tag</span>
                  <span class="ml-6 flex h-7 items-center">
                    <!--
                        Expand/collapse icon, toggle classes based on section open state.

                        Open: "-rotate-180", Closed: "rotate-0"
                      -->
                    <svg
                      class="rotate-0 h-5 w-5 transform"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  </span>
                </button>
              </legend>
              <div class="px-4 pb-2 pt-4" id="filter-section-0">
                <div class="space-y-4">
                  <div :for={tag <- @live_tags} class="flex items-center">
                    <input
                      id="color-0-mobile"
                      name="color[]"
                      value="white"
                      type="checkbox"
                      class="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
                    />
                    <label for="color-0-mobile" class="ml-3 text-sm"><%= tag.name %></label>
                  </div>
                </div>
              </div>
            </fieldset>

            <form>
              <div class="flex flex-col justify-between">
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
                    to: ~p"/streams",
                    class: "btn btn-primary"
                  ) %>
                </div>
              </div>
            </form>
          </div>
        </aside>

        <div class="bg-slate-800 lg:col-span-10 p-4">
          <Title.h1><%= @title %></Title.h1>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-2">
            <%= for channel <- @channels do %>
              <ChannelPreview.thumbnail_and_info channel={channel} />
            <% end %>
          </div>
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

    live_tags = Glimesh.ChannelCategories.list_live_tags()

    # |> Enum.into(%{})

    live_subcategories = Glimesh.ChannelCategories.list_live_subcategories()

    # |> Enum.into(%{})

    socket
    |> assign(channels: channels, live_tags: live_tags, live_subcategories: live_subcategories)
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
