defmodule GlimeshWeb.Oauth2Provider.AuthorizedApplicationController do
  @moduledoc false
  use GlimeshWeb, :controller
  alias ExOauth2Provider.Applications
  alias Plug.Conn

  def index(conn, _params) do
    applications = Applications.get_authorized_applications_for(conn.assigns[:current_user], [otp_app: :glimesh])

    render(conn, "index.html", applications: applications)
  end

  def delete(conn, %{"uid" => uid}) do
    config = [otp_app: :glimesh]
    {:ok, _application} =
      uid
      |> Applications.get_application!(config)
      |> Applications.revoke_all_access_tokens_for(conn.assigns[:current_user], config)

    conn
    |> put_flash(:info, "Application revoked.")
    |> redirect(to: Routes.authorized_application_path(conn, :index))
  end
end
