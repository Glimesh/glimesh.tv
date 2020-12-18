defmodule GlimeshWeb.Oauth2Provider.AuthorizedApplicationController do
  @moduledoc false
  use GlimeshWeb, :controller
  alias ExOauth2Provider.Applications

  plug :put_layout, "user-sidebar.html"

  def index(conn, _params) do
    applications =
      Applications.get_authorized_applications_for(conn.assigns[:current_user], otp_app: :glimesh)
      |> Glimesh.Repo.preload(:app)

    render(conn, "index.html", format_page_title(gettext("Authorized Applications")),
      applications: applications
    )
  end

  def delete(conn, %{"uid" => uid}) do
    config = [otp_app: :glimesh]

    {:ok, _application} =
      uid
      |> Applications.get_application!(config)
      |> Applications.revoke_all_access_tokens_for(conn.assigns[:current_user], config)

    conn
    |> put_flash(:info, gettext("Application revoked."))
    |> redirect(to: Routes.authorized_application_path(conn, :index))
  end
end
