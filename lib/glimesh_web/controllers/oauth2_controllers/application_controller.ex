defmodule GlimeshWeb.Oauth2Provider.ApplicationController do
  @moduledoc false
  use GlimeshWeb, :controller

  alias ExOauth2Provider.Applications
  alias Plug.Conn

  plug :assign_native_redirect_uri when action in [:new, :create, :edit, :update]

  def index(conn, _params) do
    applications = Applications.get_applications_for(conn.assigns[:current_user], [otp_app: :glimesh])

    render(conn, "index.html", applications: applications)
  end

  def new(conn, _params) do
    config = [otp_app: :glimesh]
    changeset =
      ExOauth2Provider.Config.application(config)
      |> struct()
      |> Applications.change_application(%{}, config)

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"oauth_application" => application_params}) do
    conn.assigns[:current_user]
    |> Applications.create_application(application_params, [otp_app: :glimesh])
    |> case do
      {:ok, application} ->
        conn
        |> put_flash(:info, "Application created successfully.")
        |> redirect(to: Routes.application_path(conn, :show, application))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"uid" => uid}) do
    application = get_application_for!(conn.assigns[:current_user], uid, [otp_app: :glimesh])

    render(conn, "show.html", application: application)
  end

  def edit(conn, %{"uid" => uid}) do
    config = [otp_app: :glimesh]
    application = get_application_for!(conn.assigns[:current_user], uid, config)
    changeset   = Applications.change_application(application, %{}, config)

    render(conn, "edit.html", changeset: changeset)
  end

  def update(conn, %{"uid" => uid, "oauth_application" => application_params}) do
    config = [otp_app: :glimesh]
    application = get_application_for!(conn.assigns[:current_user], uid, config)

    case Applications.update_application(application, application_params, config) do
      {:ok, application} ->
        conn
        |> put_flash(:info, "Application updated successfully.")
        |> redirect(to: Routes.application_path(conn, :show, application))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  def delete(conn, %{"uid" => uid}) do
    config = [otp_app: :glimesh]
    {:ok, _application} =
      conn.assigns[:current_user]
      |> get_application_for!(uid, config)
      |> Applications.delete_application(config)

    conn
    |> put_flash(:info, "Application deleted successfully.")
    |> redirect(to: Routes.application_path(conn, :index))
  end

  defp get_application_for!(resource_owner, uid, config) do
    Applications.get_application_for!(resource_owner, uid, config)
  end

  defp assign_native_redirect_uri(conn, _opts) do
    native_redirect_uri = ExOauth2Provider.Config.native_redirect_uri([otp_app: :glimesh])

    Conn.assign(conn, :native_redirect_uri, native_redirect_uri)
  end
end
