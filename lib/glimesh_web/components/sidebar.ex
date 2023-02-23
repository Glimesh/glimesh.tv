defmodule GlimeshWeb.Components.Sidebar do
  use GlimeshWeb, :component

  defmodule LinkGroup do
    defstruct [:label, :links]
  end

  defmodule Link do
    defstruct [:to, :icon, :label]
  end

  attr :groups, :list, required: true
  attr :active_path, :string

  def sidebar(assigns) do
    ~H"""
    <aside class="w-64 h-full" aria-label="Sidebar">
      <div class="overflow-y-auto py-4 px-3 bg-gray-800">
        <%= for group <- @groups do %>
          <.sidebar_group group={group} active_path={@active_path} />
        <% end %>
      </div>
    </aside>
    """
  end

  attr :group, GlimeshWeb.Components.Sidebar.LinkGroup, required: true
  attr :active_path, :string

  def sidebar_group(assigns) do
    ~H"""
    <div class="p-2 text-lg font-normal"><%= @group.label %></div>
    <ul class="space-y-2 mb-4">
      <%= for link <- @group.links do %>
        <.sidebar_link link={link} active_path={@active_path} />
      <% end %>
    </ul>
    """
  end

  attr :link, GlimeshWeb.Components.Sidebar.Link, required: true
  attr :active_path, :string

  def sidebar_link(assigns) do
    classes = "text-white"
    active = if assigns.link.to == assigns.active_path, do: "text-red-800", else: ""

    ~H"""
    <li>
      <.link
        navigate={@link.to}
        class="flex items-center p-2 text-base font-normal rounded-lg text-white hover:bg-gray-700"
      >
        <%= @link.icon.(%{
          class: "flex-shrink-0 w-6 h-6 transition duration-75 text-gray-400 group-hover:text-white"
        }) %>
        <span class="ml-3"><%= @link.label %></span>
      </.link>
    </li>
    """
  end
end

defmodule GlimeshWeb.Components.UserSettingsSidebar do
  use GlimeshWeb, :component

  attr :active_path, :string

  def sidebar(assigns) do
    assigns = assign(assigns, :groups, link_groups())

    ~H"""
    <GlimeshWeb.Components.Sidebar.sidebar groups={@groups} active_path={@active_path} />
    """
  end

  defp link_groups,
    do: [
      %GlimeshWeb.Components.Sidebar.LinkGroup{
        label: gettext("Settings"),
        links: [
          %GlimeshWeb.Components.Sidebar.Link{
            to: ~p"/users/settings/profile",
            icon: &Icons.user/1,
            label: gettext("Profile")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: ~p"/users/payments",
            icon: &Icons.money_bill/1,
            label: gettext("Payments")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: ~p"/users/settings/preference",
            icon: &Icons.cog/1,
            label: gettext("Preferences")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: ~p"/users/settings/notifications",
            icon: &Icons.envelope/1,
            label: gettext("Notifications")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: Routes.user_security_path(GlimeshWeb.Endpoint, :index),
            icon: &Icons.lock/1,
            label: gettext("Security")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: ~p"/users/settings/authorizations",
            icon: &Icons.robot/1,
            label: gettext("Authorizations")
          }
        ]
      },
      %GlimeshWeb.Components.Sidebar.LinkGroup{
        label: gettext("Channel"),
        links: [
          %GlimeshWeb.Components.Sidebar.Link{
            to: Routes.user_settings_path(GlimeshWeb.Endpoint, :stream),
            icon: &Icons.user/1,
            label: gettext("Channel Settings")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: Routes.user_settings_path(GlimeshWeb.Endpoint, :addons),
            icon: &Icons.user/1,
            label: gettext("Support Modal")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: Routes.user_settings_path(GlimeshWeb.Endpoint, :channel_statistics),
            icon: &Icons.user/1,
            label: gettext("Statistics")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: Routes.channel_moderator_path(GlimeshWeb.Endpoint, :index),
            icon: &Icons.user/1,
            label: gettext("Moderators")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: Routes.user_settings_path(GlimeshWeb.Endpoint, :emotes),
            icon: &Icons.user/1,
            label: gettext("Emotes")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: Routes.user_settings_path(GlimeshWeb.Endpoint, :hosting),
            icon: &Icons.user/1,
            label: gettext("Hosting")
          }
        ]
      },
      %GlimeshWeb.Components.Sidebar.LinkGroup{
        label: gettext("Developer"),
        links: [
          %GlimeshWeb.Components.Sidebar.Link{
            to: Routes.user_applications_path(GlimeshWeb.Endpoint, :index),
            icon: &Icons.user/1,
            label: gettext("Applications")
          }
        ]
      }
    ]

  attr :to, :string, required: true
  attr :active_path, :string, required: true
  attr :icon, :any, required: true

  slot :inner_block, required: true

  def nav_link(assigns) do
    classes = "text-white"
    active = if assigns.to == assigns.active_path, do: "text-red-800", else: ""

    ~H"""
    <li>
      <.link
        navigate={@to}
        class="flex items-center p-2 text-base font-normal rounded-lg text-white hover:bg-gray-700"
      >
        <%= @icon.(%{
          class: "flex-shrink-0 w-6 h-6 transition duration-75 text-gray-400 group-hover:text-white"
        }) %>
        <span class="ml-3"><%= render_slot(@inner_block) %></span>
      </.link>
    </li>
    """
  end
end
