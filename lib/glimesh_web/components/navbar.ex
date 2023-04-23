defmodule GlimeshWeb.Components.Navbar do
  use GlimeshWeb, :component

  alias Phoenix.LiveView.JS

  def navbar(assigns) do
    ~H"""
    <nav class="bg-gray-800/75 sticky top-0 z-10">
      <div class="mx-auto px-2 sm:px-6 lg:px-8">
        <div class="relative flex h-16 items-center justify-between">
          <div class="absolute inset-y-0 left-0 flex items-center sm:hidden">
            <!-- Mobile menu button-->
            <button
              type="button"
              class="inline-flex items-center justify-center rounded-md p-2 text-gray-400 hover:bg-gray-700 hover:text-white focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
              aria-controls="mobile-menu"
              aria-expanded="false"
            >
              <span class="sr-only">Open main menu</span>
              <!--
                Icon when menu is closed.

                Heroicon name: outline/bars-3

                Menu open: "hidden", Menu closed: "block"
              -->
              <svg
                class="block h-6 w-6"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                aria-hidden="true"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5"
                />
              </svg>
              <!--
                Icon when menu is open.

                Heroicon name: outline/x-mark

                Menu open: "block", Menu closed: "hidden"
              -->
              <svg
                class="hidden h-6 w-6"
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                stroke-width="1.5"
                stroke="currentColor"
                aria-hidden="true"
              >
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
          <div class="flex flex-1 items-center justify-center sm:items-stretch sm:justify-start">
            <div class="flex flex-shrink-0 items-center">
              <.link navigate={~p"/"}>
                <img
                  class="block h-8 w-auto sm:hidden"
                  src={~p"/images/logos/glimesh-beta.png"}
                  alt="Glimesh"
                />
                <img
                  class="hidden h-8 w-auto sm:block"
                  src={~p"/images/logos/Beta_New_Banner_2.png"}
                  alt="Glimesh"
                />
              </.link>
            </div>
            <div class="hidden sm:ml-6 sm:block">
              <div class="flex space-x-2">
                <div class="group inline-block relative">
                  <.nav_link
                    navigate={~p"/streams"}
                    class="rounded-lg group-hover:bg-gray-700 group-hover:rounded-b-none"
                  >
                    <%= gettext("Browse") %>
                  </.nav_link>

                  <div class="absolute hidden rounded-lg rounded-tl-none bg-gray-700 z-10 pt-1 group-hover:block">
                    <div class="flex justify-between">
                      <%= for {name, category, icon} <- list_categories() do %>
                        <.link
                          navigate={~p"/streams/#{category}"}
                          class="py-2 px-4 hover:text-white text-center flex flex-col items-center text-slate-300"
                        >
                          <%= icon.(%{class: "h-8 text-center"}) %>
                          <small class="text-center"><%= name %></small>
                        </.link>
                      <% end %>
                    </div>
                  </div>
                </div>

                <%= if assigns[:current_user] do %>
                  <.nav_link navigate={~p"/streams/following"}>
                    <%= gettext("Following") %>
                    <%= cond do %>
                      <% count_live = count_live_following_channels(@conn) -> %>
                        <span class="badge badge-danger align-top ml-2"><%= count_live %></span>
                      <% count_hosted = count_live_hosted_channels(@conn) -> %>
                        <span class="badge badge-primary align-top ml-2"><%= count_hosted %></span>
                      <% true -> %>
                    <% end %>
                  </.nav_link>
                <% end %>
                <.nav_link navigate={~p"/events"}>
                  <%= gettext("Events") %>
                </.nav_link>
              </div>
            </div>
          </div>
          <div class="absolute inset-y-0 right-0 flex items-center pr-2 sm:static sm:inset-auto sm:ml-6 sm:pr-0">
            <%= if @current_user do %>
              <%= live_render(@conn, GlimeshWeb.Components.Notifications,
                id: "notifications",
                sticky: true
              ) %>
              <!-- Profile dropdown -->
              <div class="relative ml-3">
                <div>
                  <button
                    type="button"
                    class="flex rounded-full bg-gray-800 text-sm focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-gray-800"
                    id="user-menu-button"
                    aria-expanded="false"
                    aria-haspopup="true"
                    phx-click={toggle_dropdown("#profile-dropdown")}
                  >
                    <span class="sr-only">Open user menu</span>
                    <img
                      class="h-8 w-8 rounded-full"
                      src={Glimesh.Avatar.url({@current_user.avatar, @current_user}, :original)}
                      alt=""
                    />
                  </button>
                </div>
                <!--
                Dropdown menu, show/hide based on menu state.

                Entering: "transition ease-out duration-100"
                  From: "transform opacity-0 scale-95"
                  To: "transform opacity-100 scale-100"
                Leaving: "transition ease-in duration-75"
                  From: "transform opacity-100 scale-100"
                  To: "transform opacity-0 scale-95"
              -->
                <div
                  id="profile-dropdown"
                  class="hidden absolute right-0 z-10 mt-2 w-48 origin-top-right rounded-md bg-gray-700 py-1 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
                  role="menu"
                  aria-orientation="vertical"
                  aria-labelledby="user-menu-button"
                  tabindex="-1"
                >
                  <!-- Active: "bg-gray-100", Not Active: "" -->
                  <Navbar.dropdown_link navigate={~p"/#{@current_user.username}/profile"}>
                    <%= gettext("Profile") %>
                  </Navbar.dropdown_link>
                  <Navbar.dropdown_link navigate={~p"/platform_subscriptions"}>
                    <%= gettext("Upgrade!") %>
                  </Navbar.dropdown_link>
                  <Navbar.dropdown_link navigate={~p"/users/payments"}>
                    <%= gettext("Payments") %>
                  </Navbar.dropdown_link>
                  <Navbar.dropdown_link navigate={~p"/users/settings/profile"}>
                    <%= gettext("Settings") %>
                  </Navbar.dropdown_link>
                  <Navbar.dropdown_link href={~p"/users/log_out"} method="delete">
                    <%= gettext("Sign Out") %>
                  </Navbar.dropdown_link>
                </div>
              </div>
            <% else %>
              <.nav_link navigate={~p"/users/register"}>
                <%= gettext("Register") %>
              </.nav_link>
              <.nav_link navigate={~p"/users/log_in"}>
                <%= gettext("Sign In") %>
              </.nav_link>
            <% end %>
          </div>
        </div>
      </div>
      <!-- Mobile menu, show/hide based on menu state. sm:hidden -->
      <div class="hidden" id="mobile-menu">
        <div class="space-y-1 px-2 pt-2 pb-3">
          <!-- Current: "bg-gray-900 text-white", Default: "text-gray-300 hover:bg-gray-700 hover:text-white" -->
          <a
            href="#"
            class="bg-gray-900 text-white block px-3 py-2 rounded-md text-base font-medium"
            aria-current="page"
          >
            Dashboard
          </a>

          <a
            href="#"
            class="text-gray-300 hover:bg-gray-700 hover:text-white block px-3 py-2 rounded-md text-base font-medium"
          >
            Team
          </a>

          <a
            href="#"
            class="text-gray-300 hover:bg-gray-700 hover:text-white block px-3 py-2 rounded-md text-base font-medium"
          >
            Projects
          </a>

          <a
            href="#"
            class="text-gray-300 hover:bg-gray-700 hover:text-white block px-3 py-2 rounded-md text-base font-medium"
          >
            Calendar
          </a>
        </div>
      </div>
    </nav>
    """
  end

  def nav_link(assigns) do
    assigns =
      assign(
        assigns,
        :class,
        [
          "flex items-center p-2 text-base font-normal rounded-lg text-white hover:bg-gray-700",
          Map.get(assigns, :class, "")
        ]
      )

    Phoenix.Component.link(assigns)
  end

  def dropdown_link(assigns) do
    assigns = assign(assigns, :class, "block px-4 py-2 text-sm hover:bg-gray-800")

    Phoenix.Component.link(assigns)
  end

  def toggle_dropdown(js \\ %JS{}, to) do
    js
    |> JS.toggle(
      in: {
        "transition ease-out duration-100",
        "transform opacity-0 scale-95",
        "transform opacity-100 scale-100"
      },
      out: {
        "transition ease-in duration-75",
        "transform opacity-100 scale-100",
        "transform opacity-0 scale-95"
      },
      to: to
    )
  end

  defp count_live_following_channels(%{assigns: %{current_user: user}}) do
    count = length(Glimesh.ChannelLookups.list_live_followed_channels(user))

    if count > 0 do
      count
    else
      nil
    end
  end

  defp count_live_following_channels(_) do
    nil
  end

  defp count_live_hosted_channels(%{assigns: %{current_user: user}}) do
    count = Glimesh.ChannelLookups.count_live_followed_channels_that_are_hosting(user)

    if count > 0 do
      count
    else
      nil
    end
  end

  defp count_live_hosted_channels(_) do
    nil
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
