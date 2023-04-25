defmodule GlimeshWeb.UserLiveAuth do
  use GlimeshWeb, :verified_routes
  import Phoenix.Component
  import Phoenix.LiveView

  def on_mount(:default, _params, session, socket) do
    {:cont, socket |> common_assigns(session)}
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = socket |> common_assigns(session)

    if socket.assigns.current_user do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  def on_mount(:user, _params, session, socket) do
    socket = socket |> common_assigns(session)

    if is_nil(socket.assigns.current_user) do
      {:halt,
       socket
       |> put_flash(:info, "You must login to access this page.")
       |> redirect(to: ~p"/users/log_in")}
    else
      {:cont, socket}
    end
  end

  def on_mount(:streamer, _params, session, socket) do
    socket = socket |> common_assigns(session)
    channel = Glimesh.ChannelLookups.get_channel_for_user(socket.assigns.current_user)

    cond do
      is_nil(socket.assigns.current_user) ->
        {:halt,
         socket
         |> put_flash(:info, "You must login to access this page.")
         |> redirect(to: ~p"/users/log_in")}

      is_nil(channel) ->
        {:halt,
         socket
         |> put_flash(:info, "You must have a channel to access this page.")
         |> redirect(to: ~p"/users/settings/create_channel")}

      true ->
        {:cont, socket |> assign(channel: channel)}
    end
  end

  def common_assigns(socket, session) do
    if session["locale"], do: Gettext.put_locale(session["locale"])

    socket
    |> assign_new(:site_theme, fn ->
      Map.get(session, "site_theme", "dark")
    end)
    |> assign_new(:current_user, fn ->
      Glimesh.Accounts.get_user_by_session_token(Map.get(session, "user_token"))
    end)
  end

  defp signed_in_path(_socket), do: ~p"/"
end
