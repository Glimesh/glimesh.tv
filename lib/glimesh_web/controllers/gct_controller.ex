defmodule GlimeshWeb.GctController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias Glimesh.Payments

  #General Routes
  def index(conn, _params) do
    render(conn, "index.html")
  end

  def username_lookup(conn, params) do
    user = Accounts.get_by_username(params["query"], true)
    render(
      conn,
      "lookup_user.html",
      user: user,
      payout_history: Payments.list_payout_history(user),
      payment_history: Payments.list_payment_history(user))
  end

  def edit_user_profile(conn, %{"username" => username}) do
    user = Accounts.get_by_username(username)
    user_changeset = Accounts.change_user_profile(user)

    render(
      conn,
      "edit_user.html",
      user: user,
      user_changeset: user_changeset
    )
  end

  def update_user_profile(conn, %{"user" => user_params, "username" => username}) do
    user = Accounts.get_by_username(username)

    case Accounts.update_user_profile(user, user_params) do
      {:ok, user} ->
        user_changeset = Accounts.change_user_profile(user)
        conn
        |> put_flash(:info, gettext("User updated successfully"))
        |> render("edit_user.html", user_changeset: user_changeset, user: user)

      {:error, changeset} ->
        render(conn, "edit_user.html", user_changeset: changeset, user: user)
    end
  end

end
