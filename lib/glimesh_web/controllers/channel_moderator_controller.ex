defmodule GlimeshWeb.ChannelModeratorController do
  use GlimeshWeb, :controller

  action_fallback GlimeshWeb.FallbackController

  alias Glimesh.StreamModeration
  alias Glimesh.Streams.ChannelModerator
  alias Glimesh.ChannelLookups

  plug :put_layout, "user-sidebar.html"

  def index(conn, _params) do
    user = conn.assigns.current_user

    channel = ChannelLookups.get_channel_for_user(conn.assigns.current_user)
    channel_moderators = StreamModeration.list_channel_moderators(user, channel)
    moderation_log = StreamModeration.list_channel_moderation_log(user, channel)
    channel_bans = StreamModeration.list_channel_bans(user, channel)

    render(conn, "index.html",
      page_title: format_page_title(gettext("Channel Moderators")),
      channel_moderators: channel_moderators,
      moderation_log: moderation_log,
      channel_bans: channel_bans
    )
  end

  def unban_user(conn, %{"username" => username}) do
    user = conn.assigns.current_user
    channel = ChannelLookups.get_channel_for_user(conn.assigns.current_user)
    unban_user = Glimesh.Accounts.get_by_username!(username)

    case Glimesh.Chat.unban_user(user, channel, unban_user) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "User unbanned successfully.")
        |> redirect(to: Routes.channel_moderator_path(conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, "Unable to unban user.")
        |> redirect(to: Routes.channel_moderator_path(conn, :index))
    end
  end

  def new(conn, _params) do
    changeset = StreamModeration.change_channel_moderator(%ChannelModerator{})

    render(conn, "new.html",
      page_title: format_page_title(gettext("Add Moderator")),
      changeset: changeset
    )
  end

  def create(conn, %{"channel_moderator" => channel_moderator_params}) do
    user = conn.assigns.current_user
    channel = ChannelLookups.get_channel_for_user(user)
    new_mod_user = Glimesh.Accounts.get_by_username(channel_moderator_params["username"])

    case StreamModeration.create_channel_moderator(
           user,
           channel,
           new_mod_user,
           channel_moderator_params
         ) do
      {:ok, channel_moderator} ->
        conn
        |> put_flash(:info, "Channel moderator created successfully.")
        |> redirect(to: Routes.channel_moderator_path(conn, :show, channel_moderator))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)

      {:error_no_user, changeset} ->
        conn = conn |> put_flash(:error, "Valid username is required.")
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    with {:ok, channel_moderator} <- StreamModeration.get_channel_moderator(user, id) do
      mod_log = StreamModeration.list_channel_moderation_log_for_mod(user, channel_moderator)
      changeset = StreamModeration.change_channel_moderator(channel_moderator)

      render(conn, "show.html",
        page_title: format_page_title(channel_moderator.user.displayname),
        channel_moderator: channel_moderator,
        changeset: changeset,
        moderation_log: mod_log
      )
    end
  end

  def update(conn, %{"id" => id, "channel_moderator" => channel_moderator_params}) do
    user = conn.assigns.current_user

    with {:ok, channel_moderator} <- StreamModeration.get_channel_moderator(user, id) do
      case StreamModeration.update_channel_moderator(
             user,
             channel_moderator,
             channel_moderator_params
           ) do
        {:ok, channel_moderator} ->
          conn
          |> put_flash(:info, "Channel moderator updated successfully.")
          |> redirect(to: Routes.channel_moderator_path(conn, :show, channel_moderator))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "edit.html", channel_moderator: channel_moderator, changeset: changeset)
      end
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    with {:ok, channel_moderator} <- StreamModeration.get_channel_moderator(user, id) do
      case StreamModeration.delete_channel_moderator(user, channel_moderator) do
        {:ok, _} ->
          conn
          |> put_flash(:info, "Channel moderator deleted successfully.")
          |> redirect(to: Routes.channel_moderator_path(conn, :index))
      end
    end
  end
end
