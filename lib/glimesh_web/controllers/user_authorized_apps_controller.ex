defmodule GlimeshWeb.UserAuthorizedAppsController do
  @moduledoc false
  use GlimeshWeb, :controller

  plug :put_layout, "user-sidebar.html"

  def index(conn, _params) do
    tokens = Glimesh.Apps.list_valid_tokens_for_user(conn.assigns[:current_user])

    render(conn, "index.html",
      page_title: format_page_title(gettext("Authorized Applications")),
      tokens: tokens
    )
  end

  def delete(conn, %{"id" => id}) do
    case Glimesh.Apps.revoke_token_by_id(conn.assigns[:current_user], id) do
      :ok ->
        conn
        |> put_flash(:info, gettext("Application revoked."))
        |> redirect(to: Routes.user_authorized_apps_path(conn, :index))

      _ ->
        conn
        |> put_flash(:error, gettext("Failed to revoke token."))
        |> redirect(to: Routes.user_authorized_apps_path(conn, :index))
    end
  end
end
