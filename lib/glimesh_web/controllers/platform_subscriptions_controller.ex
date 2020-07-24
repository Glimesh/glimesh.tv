defmodule GlimeshWeb.PlatformSubscriptionsController do
  use GlimeshWeb, :controller

  alias Glimesh.Payments
  alias Glimesh.Payments.PlatformSubscriptions

  def index(conn, _params) do
    platform_subscriptions = Payments.list_platform_subscriptions()
    render(conn, "index.html", platform_subscriptions: platform_subscriptions)
  end

  def new(conn, _params) do
    changeset = Payments.change_platform_subscriptions(%PlatformSubscriptions{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"platform_subscriptions" => platform_subscriptions_params}) do
    case Payments.create_platform_subscriptions(platform_subscriptions_params) do
      {:ok, platform_subscriptions} ->
        conn
        |> put_flash(:info, "Platform subscriptions created successfully.")
        |> redirect(to: Routes.platform_subscriptions_path(conn, :show, platform_subscriptions))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    platform_subscriptions = Payments.get_platform_subscriptions!(id)
    render(conn, "show.html", platform_subscriptions: platform_subscriptions)
  end

  def edit(conn, %{"id" => id}) do
    platform_subscriptions = Payments.get_platform_subscriptions!(id)
    changeset = Payments.change_platform_subscriptions(platform_subscriptions)
    render(conn, "edit.html", platform_subscriptions: platform_subscriptions, changeset: changeset)
  end

  def update(conn, %{"id" => id, "platform_subscriptions" => platform_subscriptions_params}) do
    platform_subscriptions = Payments.get_platform_subscriptions!(id)

    case Payments.update_platform_subscriptions(platform_subscriptions, platform_subscriptions_params) do
      {:ok, platform_subscriptions} ->
        conn
        |> put_flash(:info, "Platform subscriptions updated successfully.")
        |> redirect(to: Routes.platform_subscriptions_path(conn, :show, platform_subscriptions))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", platform_subscriptions: platform_subscriptions, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    platform_subscriptions = Payments.get_platform_subscriptions!(id)
    {:ok, _platform_subscriptions} = Payments.delete_platform_subscriptions(platform_subscriptions)

    conn
    |> put_flash(:info, "Platform subscriptions deleted successfully.")
    |> redirect(to: Routes.platform_subscriptions_path(conn, :index))
  end
end
