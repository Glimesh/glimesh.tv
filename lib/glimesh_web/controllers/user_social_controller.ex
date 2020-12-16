defmodule GlimeshWeb.UserSocialController do
  use GlimeshWeb, :controller

  import GlimeshWeb.Gettext

  alias Glimesh.Socials

  def twitter(conn, params) do
    with {:ok, access_token} <-
           ExTwitter.access_token(params["oauth_verifier"], params["oauth_token"]),
         {:ok, _} <-
           Glimesh.Socials.Twitter.handle_user_connect(conn.assigns.current_user, access_token) do
      redirect(conn, to: Routes.user_settings_path(conn, :profile))
    else
      {:error, msg} when is_binary(msg) ->
        conn
        |> put_flash(:error, gettext("There was a problem linking your account: ") <> msg)
        |> redirect(to: Routes.user_settings_path(conn, :profile))

      {:error, %Ecto.Changeset{errors: [platform: {"has already been taken", _}]}} ->
        conn
        |> put_flash(
          :error,
          gettext("This social account has already been linked to another user.")
        )
        |> redirect(to: Routes.user_settings_path(conn, :profile))

      {:error, _unknown_error} ->
        conn
        |> put_flash(:error, gettext("There was a problem linking your account."))
        |> redirect(to: Routes.user_settings_path(conn, :profile))
    end
  end

  def disconnect(conn, %{"platform" => platform}) do
    user = conn.assigns.current_user

    case Socials.disconnect_user_social(user, platform) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("Successfully disconnected your social account."))
        |> redirect(to: Routes.user_settings_path(conn, :profile))

      _ ->
        conn
        |> put_flash(:error, gettext("There was a problem disconnecting your social account."))
        |> redirect(to: Routes.user_settings_path(conn, :profile))
    end
  end
end
