defmodule GlimeshWeb.UserApplicationsController do
  use GlimeshWeb, :controller

  alias Glimesh.Apps
  alias Glimesh.Apps.App

  plug :put_layout, "user-sidebar.html"

  plug :assign_user

  def index(conn, _params) do
    applications = Apps.list_apps_for_user(conn.assigns.user)

    render(conn, "index.html", applications: applications)
  end

  def show(conn, %{"id" => id}) do
    applications = Apps.list_apps_for_user(conn.assigns.user)
    application = Apps.get_app!(id)

    if Apps.can_show_app?(conn.assigns.user, application) do
      render(conn, "show.html", application: application, applications: applications)
    else
      unauthorized(conn)
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
        |> put_flash(:info, "Application created successfully.")
        |> redirect(to: Routes.user_applications_path(conn, :show, application.id))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => id}) do
    application = Apps.get_app!(id)
    changeset = Apps.change_app(application)

    if Apps.can_edit_app?(conn.assigns.user, application) do
      render(conn, "edit.html", application: application, changeset: changeset)
    else
      unauthorized(conn)
    end
  end

  def update(conn, %{"id" => id, "app" => application_params}) do
    application = Apps.get_app!(id)

    if Apps.can_edit_app?(conn.assigns.user, application) do
      case Apps.update_app(application, application_params) do
        {:ok, application} ->
          conn
          |> put_flash(:info, "Application updated successfully.")
          |> redirect(to: Routes.user_applications_path(conn, :show, application))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "edit.html", application: application, changeset: changeset)
      end
    else
      unauthorized(conn)
    end
  end

  defp assign_user(conn, _opts) do
    user = conn.assigns.current_user

    conn |> assign(:user, user)
  end
end
