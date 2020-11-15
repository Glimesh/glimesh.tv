defmodule GlimeshWeb.UserApplicationsController do
  use GlimeshWeb, :controller

  alias Glimesh.Apps
  alias Glimesh.Apps.App

  action_fallback GlimeshWeb.FallbackController

  plug :put_layout, "user-sidebar.html"

  plug :assign_user

  def index(conn, _params) do
    applications = Apps.list_apps(conn.assigns.user)

    render(conn, "index.html", applications: applications)
  end

  def show(conn, %{"id" => id}) do
    applications = Apps.list_apps(conn.assigns.user)

    with {:ok, application} <- Apps.get_app(conn.assigns.user, id) do
      render(conn, "show.html", application: application, applications: applications)
    end
  end

  def new(conn, _params) do
    changeset = Apps.change_app(%App{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"app" => application_params}) do
    user = conn.assigns.current_user

    case Apps.create_app(user, application_params) do
      {:ok, application} ->
        conn
        |> put_flash(:info, gettext("Application created successfully."))
        |> redirect(to: Routes.user_applications_path(conn, :show, application.id))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    with {:ok, app} <- Apps.get_app(conn.assigns.user, id) do
      changeset = Apps.change_app(app)
      render(conn, "edit.html", application: app, changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "app" => application_params}) do
    user = conn.assigns.user

    with {:ok, app} <- Apps.get_app(user, id) do
      case Apps.update_app(user, app, application_params) do
        {:ok, app} ->
          conn
          |> put_flash(:info, gettext("Application updated successfully."))
          |> redirect(to: Routes.user_applications_path(conn, :show, app))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "edit.html", application: app, changeset: changeset)

        {:error, :unauthorized} ->
          conn
          |> put_flash(:error, gettext("You do not have permission to update this app."))
          |> redirect(to: Routes.user_applications_path(conn, :edit, app))
      end
    end
  end

  def rotate(conn, %{"id" => id}) do
    user = conn.assigns.user

    with {:ok, app} <- Apps.get_app(user, id) do
      case Apps.rotate_oauth_app(user, app) do
        {:ok, _oauth_app} ->
          conn
          |> put_flash(:info, gettext("OAuth Client ID & Client Secret rotated successfully."))
          |> redirect(to: Routes.user_applications_path(conn, :show, app))

        {:error, :unauthorized} ->
          conn
          |> put_flash(:error, gettext("You do not have permission to rotate this apps keys."))
          |> redirect(to: Routes.user_applications_path(conn, :show, app))
      end
    end
  end

  defp assign_user(conn, _opts) do
    user = conn.assigns.current_user

    conn |> assign(:user, user)
  end
end
