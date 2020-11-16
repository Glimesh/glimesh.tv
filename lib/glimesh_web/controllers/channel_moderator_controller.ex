defmodule GlimeshWeb.ChannelModeratorController do
  use GlimeshWeb, :controller

  alias Glimesh.Streams
  alias Glimesh.Streams.ChannelModerator

  plug :put_layout, "user-sidebar.html"

  def index(conn, _params) do
    channel = Streams.get_channel_for_user(conn.assigns.current_user)
    channel_moderators = Streams.list_channel_moderators(channel)
    moderation_log = Streams.list_channel_moderation_log(channel)
    channel_bans = Streams.list_channel_bans(channel)

    render(conn, "index.html",
      channel_moderators: channel_moderators,
      moderation_log: moderation_log,
      channel_bans: channel_bans
    )
  end

  def unban_user(conn, %{"username" => username}) do
    channel = Streams.get_channel_for_user(conn.assigns.current_user)
    unban_user = Glimesh.Accounts.get_by_username!(username)

    case Glimesh.Chat.unban_user(conn.assigns.current_user, channel, unban_user) do
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
    changeset = Streams.change_channel_moderator(%ChannelModerator{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"channel_moderator" => channel_moderator_params}) do
    channel = Streams.get_channel_for_user(conn.assigns.current_user)
    mod_user = Glimesh.Accounts.get_by_username(channel_moderator_params["username"])

    case Streams.create_channel_moderator(channel, mod_user, channel_moderator_params) do
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
    channel_moderator = Streams.get_channel_moderator!(id)

    if Streams.can_show_mod?(conn.assigns.current_user, channel_moderator) do
      moderation_log = Streams.list_channel_moderation_log_for_mod(channel_moderator)
      changeset = Streams.change_channel_moderator(channel_moderator)

      render(conn, "show.html",
        channel_moderator: channel_moderator,
        changeset: changeset,
        moderation_log: moderation_log
      )
    else
      unauthorized(conn)
    end
  end

  def update(conn, %{"id" => id, "channel_moderator" => channel_moderator_params}) do
    channel_moderator = Streams.get_channel_moderator!(id)

    if Streams.can_edit_mod?(conn.assigns.current_user, channel_moderator) do
      case Streams.update_channel_moderator(channel_moderator, channel_moderator_params) do
        {:ok, channel_moderator} ->
          conn
          |> put_flash(:info, "Channel moderator updated successfully.")
          |> redirect(to: Routes.channel_moderator_path(conn, :show, channel_moderator))

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, "edit.html", channel_moderator: channel_moderator, changeset: changeset)
      end
    else
      unauthorized(conn)
    end
  end

  def delete(conn, %{"id" => id}) do
    channel_moderator = Streams.get_channel_moderator!(id)

    if Streams.can_edit_mod?(conn.assigns.current_user, channel_moderator) do
      {:ok, _channel_moderator} = Streams.delete_channel_moderator(channel_moderator)

      conn
      |> put_flash(:info, "Channel moderator deleted successfully.")
      |> redirect(to: Routes.channel_moderator_path(conn, :index))
    else
      unauthorized(conn)
    end
  end
end
