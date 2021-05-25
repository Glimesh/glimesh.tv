defmodule GlimeshWeb.GctController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias Glimesh.ChannelCategories
  alias Glimesh.ChannelLookups
  alias Glimesh.CommunityTeam
  alias Glimesh.Payments
  alias Glimesh.Streams

  action_fallback GlimeshWeb.GCTFallbackController

  plug :put_layout, "gct-sidebar.html"

  # General Routes
  def index(conn, _params) do
    current_user = conn.assigns.current_user
    view_audit_log = Bodyguard.permit?(Glimesh.CommunityTeam, :view_audit_log, current_user)

    render(
      conn,
      "index.html",
      can_view_audit_log: view_audit_log,
      page_title: format_page_title("GCT Dashboard")
    )
  end

  def audit_log(conn, _params) do
    current_user = conn.assigns.current_user

    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam, :view_audit_log, current_user) do
      render(conn, "audit_log.html", page_title: format_page_title("Audit Log"))
    end
  end

  def emotes(conn, _params) do
    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam, :manage_emotes, conn.assigns.current_user) do
      conn
      |> Phoenix.LiveView.Controller.live_render(GlimeshWeb.GctLive.ManageEmotes)
    end
  end

  def unauthorized(conn, _params) do
    current_user = conn.assigns.current_user
    CommunityTeam.log_unauthorized_access(current_user)
    render(conn, "unauthorized.html")
  end

  # Looking up/editing a user

  def username_lookup(conn, params) do
    gct_user = conn.assigns.current_user
    query = params["query"]

    user =
      case parse_user_query(query) do
        "username" -> Accounts.get_by_username(query, true)
        "email" -> Accounts.get_user_by_email(query)
        "user_id" -> Accounts.get_user!(query)
      end

    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam, :view_user, gct_user, user) do
      view_billing = Bodyguard.permit?(Glimesh.CommunityTeam, :view_billing_info, gct_user, user)

      if user do
        CommunityTeam.create_lookup_audit_entry(gct_user, user)

        render(
          conn,
          "lookup_user.html",
          user: user,
          payout_history: [],
          payment_history: Payments.list_payment_history(user),
          view_billing?: view_billing,
          page_title: format_page_title("#{user.displayname}")
        )
      else
        render(conn, "invalid_user.html")
      end
    end
  end

  def user_chat_log(conn, %{"user_id" => user_id}) do
    current_user = conn.assigns.current_user
    user = Accounts.get_user!(user_id)

    if user do
      with :ok <-
             Bodyguard.permit(Glimesh.CommunityTeam, :view_chat_logs, current_user, user) do
        CommunityTeam.create_audit_entry(current_user, %{
          action: "view user chat log",
          target: user.username,
          verbose_required: true
        })

        render(conn, "user_chat_log.html",
          user: user,
          page_title: format_page_title("Chat Log - #{user.displayname}")
        )
      end
    end
  end

  def edit_user_profile(conn, %{"username" => username}) do
    current_user = conn.assigns.current_user
    user = Accounts.get_by_username(username, true)
    twitter_auth_url = Glimesh.Socials.Twitter.authorize_url(conn)

    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam, :edit_user_profile, current_user, user) do
      CommunityTeam.create_audit_entry(current_user, %{
        action: "view edit profile",
        target: username,
        verbose_required: true
      })

      if user do
        user_changeset = Accounts.change_user_profile(user)

        render(
          conn,
          "edit_user_profile.html",
          user: user,
          user_changeset: user_changeset,
          twitter_auth_url: twitter_auth_url,
          page_title: format_page_title("Editing Profile - #{user.displayname}")
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
      CommunityTeam.create_audit_entry(current_user, %{
        action: "edited profile",
        target: username,
        verbose_required: false,
        more_details: CommunityTeam.generate_update_user_profile_more_details(user, user_params)
      })

      case Accounts.update_user_profile(user, user_params) do
        {:ok, user} ->
          conn
          |> put_flash(:info, gettext("User updated successfully"))
          |> redirect(to: Routes.gct_path(conn, :edit_user_profile, user.username))

        {:error, changeset} ->
          render(conn, "edit_user_profile.html",
            user_changeset: changeset,
            user: user,
            twitter_auth_url: Glimesh.Socials.Twitter.authorize_url(conn)
          )
      end
    end
  end

  def edit_user(conn, %{"username" => username}) do
    current_user = conn.assigns.current_user
    user = Accounts.get_by_username(username, true)

    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam, :edit_user, current_user, user) do
      CommunityTeam.create_audit_entry(current_user, %{
        action: "view edit user",
        target: username,
        verbose_required: true
      })

      if user do
        user_changeset = CommunityTeam.change_user(user)

        view_billing =
          Bodyguard.permit?(
            Glimesh.CommunityTeam,
            :view_billing_info,
            current_user,
            user
          )

        render(
          conn,
          "edit_user.html",
          user: user,
          user_changeset: user_changeset,
          view_billing?: view_billing,
          page_title: format_page_title("Editing Profile - #{user.displayname}")
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
      CommunityTeam.create_audit_entry(current_user, %{
        action: "edited user",
        target: username,
        verbose_required: false,
        more_details: CommunityTeam.generate_update_user_more_details(user, user_params)
      })

      case CommunityTeam.update_user(user, user_params) do
        {:ok, user} ->
          conn
          |> put_flash(:info, gettext("User updated successfully"))
          |> redirect(to: Routes.gct_path(conn, :edit_user, user.username))

        {:error, changeset} ->
          view_billing =
            Bodyguard.permit?(
              Glimesh.CommunityTeam,
              :view_billing_info,
              current_user,
              user
            )

          render(
            conn,
            "edit_user.html",
            user: user,
            user_changeset: changeset,
            view_billing?: view_billing
          )
      end
    end
  end

  # Looking up/editing a channel

  def channel_lookup(conn, params) do
    query = params["query"]

    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam, :view_channel, conn.assigns.current_user) do
      unless params["query"] == "",
        do:
          CommunityTeam.create_audit_entry(conn.assigns.current_user, %{
            action: "lookup channel",
            target: params["query"],
            verbose_required: true
          })

      channel =
        case parse_channel_query(query) do
          "channel_id" -> ChannelLookups.get_channel!(query)
          "username" -> ChannelLookups.get_channel_for_username(query, true)
        end

      if channel do
        render(
          conn,
          "lookup_channel.html",
          channel: channel,
          categories: ChannelCategories.list_categories_for_select(),
          page_title: format_page_title("Channel Info - #{channel.user.displayname}")
        )
      else
        render(conn, "invalid_user.html")
      end
    end
  end

  def channel_chat_log(conn, %{"channel_id" => channel_id}) do
    current_user = conn.assigns.current_user
    channel = ChannelLookups.get_channel(channel_id)

    if channel do
      with :ok <-
             Bodyguard.permit(Glimesh.CommunityTeam, :view_chat_logs, current_user, channel.user) do
        CommunityTeam.create_audit_entry(current_user, %{
          action: "view channel chat log",
          target: channel_id,
          verbose_required: true
        })

        render(conn, "channel_chat_log.html",
          channel: channel,
          page_title: format_page_title("Chat Log - #{channel.user.displayname}")
        )
      end
    end
  end

  def edit_channel(conn, %{"channel_id" => channel_id}) do
    current_user = conn.assigns.current_user
    channel = ChannelLookups.get_channel(channel_id)

    if channel do
      with :ok <-
             Bodyguard.permit(Glimesh.CommunityTeam, :edit_channel, current_user, channel.user) do
        CommunityTeam.create_audit_entry(current_user, %{
          action: "view edit channel",
          target: channel_id,
          verbose_required: true
        })

        channel_changeset = Streams.change_channel(channel)

        disable_delete_button =
          Kernel.not(
            Bodyguard.permit?(
              Glimesh.CommunityTeam,
              :soft_delete_channel,
              current_user,
              channel.user
            )
          )

        render(
          conn,
          "edit_channel.html",
          channel: channel,
          channel_changeset: channel_changeset,
          categories: ChannelCategories.list_categories_for_select(),
          channel_delete_disabled: disable_delete_button,
          page_title: format_page_title("Edit Channel - #{channel.user.displayname}")
        )
      end
    else
      render(conn, "invalid_user.html")
    end
  end

  def update_channel(conn, %{"channel" => channel_params, "channel_id" => channel_id}) do
    current_user = conn.assigns.current_user
    channel = ChannelLookups.get_channel!(channel_id)

    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam, :edit_channel, current_user, channel.user) do
      case Streams.update_channel(current_user, channel, channel_params) do
        {:ok, channel} ->
          create_audit_entry_channel(
            current_user,
            "edited channel",
            channel.user.username,
            false,
            CommunityTeam.generate_update_channel_more_details(channel, channel_params)
          )

          conn
          |> put_flash(:info, gettext("Channel updated successfully"))
          |> redirect(to: Routes.gct_path(conn, :edit_channel, channel.id))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "edit_channel.html",
            channel: channel,
            channel_changeset: changeset,
            categories: ChannelCategories.list_categories_for_select(),
            channel_delete_disabled:
              Kernel.not(
                Bodyguard.permit?(
                  Glimesh.CommunityTeam,
                  :soft_delete_channel,
                  current_user,
                  channel.user
                )
              )
          )

        {:error, :unauthorized} ->
          create_audit_entry_channel(
            current_user,
            "tried to edit channel, but was unauthorized",
            channel.user.username,
            false,
            "User was successfully blocked from updating channel"
          )

          conn
          |> put_flash(:error, gettext("Unauthorized. This attempt has been logged."))
          |> redirect(to: Routes.gct_path(conn, :index))
      end
    end
  end

  def delete_channel(conn, %{"channel_id" => channel_id}) do
    current_user = conn.assigns.current_user
    channel = ChannelLookups.get_channel!(channel_id)

    with :ok <-
           Bodyguard.permit(
             Glimesh.CommunityTeam,
             :soft_delete_channel,
             current_user,
             channel.user
           ) do
      case CommunityTeam.soft_delete_channel(channel, current_user) do
        {:ok, _} ->
          create_audit_entry_channel(current_user, "delete channel", channel.user.username, false)

          conn
          |> put_flash(:info, "Channel deleted successfully.")
          |> redirect(to: Routes.gct_path(conn, :index))

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "An issue occurred when trying to delete the channel.")
          |> redirect(to: Routes.gct_path(conn, :edit_channel, channel_id))
      end
    end
  end

  def shutdown_channel(conn, %{"channel_id" => channel_id}) do
    current_user = conn.assigns.current_user
    channel = ChannelLookups.get_channel!(channel_id)

    with :ok <-
           Bodyguard.permit(
             Glimesh.CommunityTeam,
             :edit_channel,
             current_user,
             channel.user
           ) do
      case CommunityTeam.shutdown_channel(channel, current_user) do
        {:ok, _} ->
          create_audit_entry_channel(
            current_user,
            "shutdown channel",
            channel.user.username,
            false
          )

          conn
          |> put_flash(
            :info,
            "Channel stream shutdown successfully and the user can no longer stream."
          )
          |> redirect(to: Routes.gct_path(conn, :index))

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "An issue occurred when trying to shutdown the channel.")
          |> redirect(to: Routes.gct_path(conn, :edit_channel, channel_id))
      end
    end
  end

  defp create_audit_entry_channel(current_user, action, target, verbose, more_details \\ "N/A") do
    CommunityTeam.create_audit_entry(current_user, %{
      action: action,
      target: target,
      verbose_required: verbose,
      more_details: more_details
    })
  end

  defp parse_user_query(string) do
    if Regex.match?(~r{\A\d*\z}, string) do
      "user_id"
    else
      if String.contains?(string, "@") do
        "email"
      else
        "username"
      end
    end
  end

  defp parse_channel_query(string) do
    if Regex.match?(~r{\A\d*\z}, string) do
      "channel_id"
    else
      "username"
    end
  end
end
