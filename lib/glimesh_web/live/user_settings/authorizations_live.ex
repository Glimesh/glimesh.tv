defmodule GlimeshWeb.UserSettings.AuthorizationsLive do
  use GlimeshWeb, :live_view

  def render(assigns) do
    ~H"""
    <Settings.page page={~p"/users/settings/authorizations"}>
      <:title><%= gettext("Authorizations") %></:title>

      <div class="p-6">
        <.table id="tokens" rows={@tokens}>
          <:col :let={token} label={gettext("Application")}><%= token.client.name %></:col>
          <:col :let={token} label={gettext("Installed At")}><%= token.inserted_at %></:col>
          <:action :let={token}>
            <%= link(gettext("Unauthorize"),
              to: ~p"/users/settings/authorizations/#{token.id}",
              method: :delete,
              data: [confirm: "Are you sure?"],
              class: "btn btn-danger btn-xs"
            ) %>
          </:action>
        </.table>
      </div>
    </Settings.page>
    """
  end

  def mount(_, _, socket) do
    {:ok,
     socket
     |> put_page_title(gettext("Authorizations"))
     |> assign(:tokens, Glimesh.Apps.list_valid_tokens_for_user(socket.assigns.current_user))}
  end
end
