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
    <aside class="lg:col-span-3 bg-slate-800/75 space-y-4 py-4" aria-label="Sidebar">
      <%= for group <- @groups do %>
        <.sidebar_group group={group} active_path={@active_path} />
      <% end %>
    </aside>
    """
  end

  attr :group, GlimeshWeb.Components.Sidebar.LinkGroup, required: true
  attr :active_path, :string

  def sidebar_group(assigns) do
    ~H"""
    <div>
      <div class="p-2 pl-4 text-lg font-normal"><%= @group.label %></div>
      <ul class="">
        <%= for link <- @group.links do %>
          <.sidebar_link link={link} active_path={@active_path} />
        <% end %>
      </ul>
    </div>
    """
  end

  attr :link, GlimeshWeb.Components.Sidebar.Link, required: true
  attr :active_path, :string

  def sidebar_link(assigns) do
    ~H"""
    <li class={[if(@link.to == @active_path, do: "bg-slate-700/75"), "cursor-pointer"]}>
      <.link
        navigate={@link.to}
        class="flex items-center px-4 p-2 text-base font-normal text-white hover:bg-slate-700/75"
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
            to: ~p"/users/settings/preferences",
            icon: &Icons.cog/1,
            label: gettext("Preferences")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: ~p"/users/settings/notifications",
            icon: &Icons.envelope/1,
            label: gettext("Notifications")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: ~p"/users/settings/security",
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
            to: ~p"/users/settings/stream",
            icon: &Icons.user/1,
            label: gettext("Channel Settings")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: ~p"/users/settings/addons",
            icon: &Icons.user/1,
            label: gettext("Support Modal")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: ~p"/users/settings/channel_statistics",
            icon: &Icons.user/1,
            label: gettext("Statistics")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: ~p"/users/settings/channel/mods",
            icon: &Icons.user/1,
            label: gettext("Moderators")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: ~p"/users/settings/emotes",
            icon: &Icons.user/1,
            label: gettext("Emotes")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: ~p"/users/settings/hosting",
            icon: &Icons.user/1,
            label: gettext("Hosting")
          },
          %GlimeshWeb.Components.Sidebar.Link{
            to: ~p"/users/settings/raiding",
            icon: &Icons.user/1,
            label: gettext("Raiding")
          }
        ]
      },
      %GlimeshWeb.Components.Sidebar.LinkGroup{
        label: gettext("Developer"),
        links: [
          %GlimeshWeb.Components.Sidebar.Link{
            to: ~p"/users/settings/applications",
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
