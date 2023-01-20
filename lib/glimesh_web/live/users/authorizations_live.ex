defmodule GlimeshWeb.Users.AuthorizationsLive do
  use GlimeshWeb, :user_settings_live_view

  def render(assigns) do
    ~H"""
    <div class="container mt-4">
      <div class="row">
        <div class="col-9">
          <h2><%= gettext("Authorized Applications") %></h2>
        </div>
        <div class="col-3"></div>
      </div>

      <div class="card">
        <div class="card-body">
          <table class="table">
            <thead>
              <tr>
                <th><%= gettext("Application") %></th>
                <th><%= gettext("Installed at") %></th>
                <th><%= gettext("Actions") %></th>
              </tr>
            </thead>
            <tbody>
              <%= for token <- @tokens do %>
                <tr>
                  <td><%= token.client.name %></td>
                  <td><%= token.inserted_at %></td>
                  <td>
                    <button
                      phx-click="delete"
                      phx-value-token-id={token.id}
                      type="button"
                      class="btn btn-danger"
                    >
                      <%= gettext("Unauthorize") %>
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    user = socket.assigns.current_user
    tokens = Glimesh.Apps.list_valid_tokens_for_user(user)

    {:ok,
     socket
     |> put_page_title("Authorized Applications")
     |> assign(:tokens, tokens)}
  end

  @impl true
  def handle_event("delete", %{"token_id" => token_id}, socket) do
    user = socket.assigns.current_user

    case Glimesh.Apps.revoke_token_by_id(user, token_id) do
      :ok ->
        socket
        |> put_flash(:info, gettext("Application revoked."))

      _ ->
        socket
        |> put_flash(:error, gettext("Failed to revoke token."))
    end
  end
end
