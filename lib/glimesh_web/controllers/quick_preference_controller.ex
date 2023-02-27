defmodule GlimeshWeb.QuickPreferenceController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias GlimeshWeb.UserAuth

  def update_preference(conn, %{"user_preference" => params}) do
    case conn.assigns.current_user do
      %Glimesh.Accounts.User{} = user ->
        set_user_preference(conn, user, params)

      _ ->
        set_session_preference(conn, params)
    end
  end

  defp set_user_preference(conn, %Glimesh.Accounts.User{} = user, preferences) do
    current_user_pref = Accounts.get_user_preference!(user)

    case Accounts.update_user_preference(current_user_pref, preferences) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("Preferences updated successfully."))
        |> put_session(:user_return_to, preferences["user_return_to"])
        |> UserAuth.log_in_user(user)

      {:error, _} ->
        # Redirect them to preferences page since they are logged in
        conn |> redirect(to: ~p"/users/settings/preference")
    end
  end

  defp set_session_preference(
         conn,
         %{"locale" => locale, "site_theme" => site_theme, "user_return_to" => user_return_to}
       ) do
    conn
    |> put_flash(:info, gettext("Preferences updated successfully."))
    |> put_session(:locale, locale)
    |> put_session(:site_theme, site_theme)
    |> redirect(to: user_return_to || ~p"/")
  end
end
