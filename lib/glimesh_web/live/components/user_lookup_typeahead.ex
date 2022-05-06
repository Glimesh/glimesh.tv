defmodule GlimeshWeb.Components.UserLookupTypeahead do
  use GlimeshWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-100">
      <input
        type="text"
        name={@field}
        value={@value}
        class={[@field <> "-input", @class]}
        phx-debounce={@timeout}
        autocomplete="off"
        phx-target={@myself}
        phx-change="suggest"
        {Map.get(assigns, :extra_params, %{})}
      />
      <%= if @matches != [] do %>
        <div class="channel-typeahead-dropdown list-group">
          <%= for user <- @matches do %>
            <div
              id={"user-lookup-#{user.id}"}
              class="list-group-item bg-primary-hover"
              phx-click="select"
              phx-value-id={user.id}
              phx-value-username={user.username}
              phx-target={@myself}
            >
              <img
                class="img-avatar"
                src={Glimesh.Avatar.url({user.avatar, user}, :original)}
                width="50"
                height="50"
              />
              &nbsp;<%= user.displayname %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(value: "")
     |> assign(matches: [])}
  end

  @impl true
  def handle_event("select", %{"username" => username}, socket) do
    {:noreply, socket |> assign(value: username) |> assign(matches: [])}
  end

  def handle_event("suggest", %{"recipient" => query}, socket) do
    results = Glimesh.Accounts.search_users(query, 1, 5)

    {:noreply, socket |> assign(:matches, results)}
  end
end
