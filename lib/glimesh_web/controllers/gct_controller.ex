defmodule GlimeshWeb.GctController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias Glimesh.CommunityTeam
  alias Glimesh.Payments
  alias Glimesh.Streams

  action_fallback GlimeshWeb.GCTFallbackController

  plug :put_layout, "gct-sidebar.html"

  # General Routes
  def index(conn, _params) do

    view_audit_log = case Bodyguard.permit(Glimesh.CommunityTeam, :view_audit_log, conn.assigns.current_user), do: (:ok -> true; {:error, :unauthorized} -> false)

    render(
      conn,
      "index.html",
      can_view_audit_log: view_audit_log
    )
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

  # Looking up/editing a user

  def username_lookup(conn, params) do
    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam, :view_user, conn.assigns.current_user, params["query"]) do
      unless params["query"] == "",
        do:
          CommunityTeam.create_audit_entry(conn.assigns.current_user, %{
            action: "lookup",
            target: params["query"],
            verbose_required?: true
          })

      user = Accounts.get_by_username(params["query"], true)

      view_billing = case Bodyguard.permit(Glimesh.CommunityTeam, :view_billing_info, conn.assigns.current_user, user), do: (:ok -> true; {:error, :unauthorized} -> false)

      if user do
        render(
          conn,
          "lookup_user.html",
          user: user,
          payout_history: Payments.list_payout_history(user),
          payment_history: Payments.list_payment_history(user),
          view_billing?: view_billing
        )
      else
        render(conn, "invalid_user.html")
      end
    end
  end

  def edit_user_profile(conn, %{"username" => username}) do
    current_user = conn.assigns.current_user
    user = Accounts.get_by_username(username, true)
    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam, :edit_user_profile, current_user, user) do
      CommunityTeam.create_audit_entry(conn.assigns.current_user, %{
        action: "view edit profile",
        target: username,
        verbose_required?: true
      })

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
  end

  def update_user_profile(conn, %{"user" => user_params, "username" => username}) do
    current_user = conn.assigns.current_user
    user = Accounts.get_by_username(username, true)
    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam, :edit_user_profile, current_user, user) do
      CommunityTeam.create_audit_entry(conn.assigns.current_user, %{
        action: "edited profile",
        target: username,
        verbose_required?: false,
        more_details: CommunityTeam.generate_update_user_profile_more_details(user, user_params)
      })

      case Accounts.update_user_profile(user, user_params) do
        {:ok, user} ->
          conn
          |> put_flash(:info, gettext("User updated successfully"))
          |> redirect(to: Routes.gct_path(conn, :edit_user_profile, user.username))

        {:error, changeset} ->
          render(conn, "edit_user_profile.html", user_changeset: changeset, user: user)
      end
    end
  end

  def edit_user(conn, %{"username" => username}) do
    current_user = conn.assigns.current_user
    user = Accounts.get_by_username(username, true)
    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam, :edit_user, current_user, user) do
      CommunityTeam.create_audit_entry(conn.assigns.current_user, %{
        action: "view edit user",
        target: username,
        verbose_required?: true
      })

      if user do
        user_changeset = Accounts.change_user(user)
        view_billing = case Bodyguard.permit(Glimesh.CommunityTeam, :view_billing_info, current_user, user), do: (:ok -> true; {:error, :unauthorized} -> false)

        render(
          conn,
          "edit_user.html",
          user: user,
          user_changeset: user_changeset,
          view_billing?: view_billing
        )
      else
        render(conn, "invalid_user.html")
      end
    end
  end

  def update_user(conn, %{"user" => user_params, "username" => username}) do
    current_user = conn.assigns.current_user
    user = Accounts.get_by_username(username, true)
    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam, :edit_user, current_user, user) do
      CommunityTeam.create_audit_entry(conn.assigns.current_user, %{
        action: "edited user",
        target: username,
        verbose_required?: false,
        more_details: CommunityTeam.generate_update_user_more_details(user, user_params)
      })

      case Accounts.update_user(user, user_params) do
        {:ok, user} ->
          conn
          |> put_flash(:info, gettext("User updated successfully"))
          |> redirect(to: Routes.gct_path(conn, :edit_user, user.username))

        {:error, changeset} ->
          render(conn, "edit_user.html", user: user, user_changeset: changeset, view_billing?: CommunityTeam.can_view_billing_info(conn.assigns.current_user))
      end
    end
  end

  # Looking up/editing a channel

  def channel_lookup(conn, params) do
    unless params["query"] == "",
      do:
        CommunityTeam.create_audit_entry(conn.assigns.current_user, %{
          action: "lookup channel",
          target: params["query"],
          verbose_required?: true
        })

    channel = Streams.get_channel_for_username!(params["query"], true)

    if channel do
      render(
        conn,
        "lookup_channel.html",
        channel: channel,
        categories: Streams.list_categories_for_select()
      )
    else
      render(conn, "invalid_user.html")
    end
  end

  def edit_channel(conn, %{"channel_id" => channel_id}) do
    unless CommunityTeam.can_edit_channel(conn.assigns.current_user) do
      redirect(conn, to: Routes.gct_path(conn, :index))
    end

    CommunityTeam.create_audit_entry(conn.assigns.current_user, %{
      action: "view edit channel",
      target: channel_id,
      verbose_required?: true
    })

    channel = Streams.get_channel!(channel_id)

    if channel do
      channel_changeset = Streams.change_channel(channel)

      render(
        conn,
        "edit_channel.html",
        channel: channel,
        channel_changeset: channel_changeset,
        categories: Streams.list_categories_for_select()
      )
    else
      render(conn, "invalid_user.html")
    end
  end

  def update_channel(conn, %{"channel" => channel_params, "channel_id" => channel_id}) do
    current_user = conn.assigns.current_user
    unless CommunityTeam.can_edit_channel(conn.assigns.current_user) do
      redirect(conn, to: Routes.gct_path(conn, :index))
    end
    channel = Streams.get_channel!(channel_id)

    case Streams.update_channel(current_user, channel, channel_params) do
      {:ok, channel} ->
        create_audit_entry_channel(current_user, "edited channel", channel.user.username, false, CommunityTeam.generate_update_channel_more_details(channel, channel_params))
        conn
        |> put_flash(:info, gettext("Channel updated successfully"))
        |> redirect(to: Routes.gct_path(conn, :edit_channel, channel.id))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit_channel.html", channel: channel, channel_changeset: changeset, categories: Streams.list_categories_for_select())

      {:error, :unauthorized} ->
        create_audit_entry_channel(current_user, "tried to edit channel, but was unauthorized", channel.user.username, false, "User was successfully blocked from updating channel")
        conn
        |> put_flash(:error, gettext("Unauthorized. This attempt has been logged."))
        |> redirect(to: Routes.gct_path(conn, :index))
    end
  end


  defp create_audit_entry_channel(current_user, action, target, verbose, more_details) do
    CommunityTeam.create_audit_entry(current_user, %{
      action: action,
      target: target,
      verbose_required?: verbose,
      more_details: more_details
    })
  end
end
