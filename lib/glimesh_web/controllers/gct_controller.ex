defmodule GlimeshWeb.GctController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias Glimesh.CommunityTeam
  alias Glimesh.Payments

  # General Routes
  def index(conn, _params) do
    render(conn, "index.html")
  end

  def username_lookup(conn, params) do
    user = Accounts.get_by_username(params["query"], true)

    if user do
      render(
        conn,
        "lookup_user.html",
        user: user,
        payout_history: Payments.list_payout_history(user),
        payment_history: Payments.list_payment_history(user)
      )
    else
      render(conn, "invalid_user.html")
    end

  end

  def edit_user_profile(conn, %{"username" => username}) do
    unless CommunityTeam.can_edit_user_profile(conn.assigns.current_user) do
      redirect(conn, to: Routes.gct_path(conn, :username_lookup, query: username))
    end

    user = Accounts.get_by_username(username, true)

    if user do
      user_changeset = Accounts.change_user_profile(user)
      render(
        conn,
        "edit_user_profile.html",
        user: user,
        user_changeset: user_changeset
      )
    else
      render(conn, "invalid_user.html")
    end
  end

  def update_user_profile(conn, %{"user" => user_params, "username" => username}) do
    user = Accounts.get_by_username(username, true)

    case Accounts.update_user_profile(user, user_params) do
      {:ok, user} ->
        user_changeset = Accounts.change_user_profile(user)

        conn
        |> put_flash(:info, gettext("User updated successfully"))
        |> render("edit_user_profile.html", user_changeset: user_changeset, user: user)

      {:error, changeset} ->
        render(conn, "edit_user_profile.html", user_changeset: changeset, user: user)
    end
  end

  def edit_user(conn, %{"username" => username}) do
    unless CommunityTeam.can_edit_user(conn.assigns.current_user) do
      redirect(conn, to: Routes.gct_path(conn, :username_lookup, query: username))
    end

    user = Accounts.get_by_username(username, true)

    if user do
      user_changeset = Accounts.change_user(user)
      render(
        conn,
        "edit_user.html",
        user: user,
        user_changeset: user_changeset
      )
    else
      render(conn, "invalid_user.html")
    end
  end

  def update_user(conn, %{"user" => user_params, "username" => username}) do
    user = Accounts.get_by_username(username, true)

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        user_changeset = Accounts.change_user(user)

        conn
        |> put_flash(:info, gettext("User updated successfully"))
        |> render("edit_user.html", user: user, user_changeset: user_changeset)

      {:error, changeset} ->
        render(conn, "edit_user.html", user: user, user_changeset: changeset)
    end
  end
end
