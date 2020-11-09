defmodule GlimeshWeb.GctController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias Glimesh.CommunityTeam
  alias Glimesh.CommunityTeam.AuditLog
  alias Glimesh.Payments

  # General Routes
  def index(conn, _params) do
    render(conn, "index.html")
  end

  def audit_log(conn, _params) do
    unless CommunityTeam.can_view_audit_log(conn.assigns.current_user) do
      redirect(conn, to: Routes.gct_path(conn, :index))
    end

    render(
      conn,
      "audit_log.html"
    )
  end

  def username_lookup(conn, params) do
    unless params["query"] == "",
      do:
        CommunityTeam.create_audit_entry(conn.assigns.current_user, %{
          action: "lookup",
          target: params["query"],
          verbose_required?: true
        })

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

    CommunityTeam.create_audit_entry(conn.assigns.current_user, %{
      action: "view edit profile",
      target: username,
      verbose_required?: true
    })

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

    CommunityTeam.create_audit_entry(conn.assigns.current_user, %{
      action: "edited profile",
      target: username,
      verbose_required?: false,
      more_details: CommunityTeam.generate_update_user_profile_more_details(user, user_params)
    })

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

    CommunityTeam.create_audit_entry(conn.assigns.current_user, %{
      action: "view edit user",
      target: username,
      verbose_required?: true
    })

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

    CommunityTeam.create_audit_entry(conn.assigns.current_user, %{
      action: "edited user",
      target: username,
      verbose_required?: false,
      more_details: CommunityTeam.generate_update_user_more_details(user, user_params)
    })

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
