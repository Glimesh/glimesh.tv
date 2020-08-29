defmodule GlimeshWeb.Oauth2Provider.AuthorizationController do
  @moduledoc false
  use GlimeshWeb, :controller

  alias ExOauth2Provider.Authorization

  def new(conn, params) do
    code = Map.get(params, "code")
    cond do
      code != nil ->
        redirect(conn, to: Routes.authorization_path(conn, :show, code))
      code == nil ->
        conn.assigns[:current_user]
        |> Authorization.preauthorize(params, [otp_app: :glimesh])
        |> case do
          {:ok, client, scopes} ->
            # add language support to the scopes as their added
            render(conn, "new.html", params: params, client: client, scopes: scopes)

          {:native_redirect, %{code: code}} ->
            redirect(conn, to: Routes.authorization_path(conn, :show, code))

          {:redirect, redirect_uri} ->
            redirect(conn, external: redirect_uri)

          {:error, error, status} ->
            conn
            |> put_status(status)
            |> render("error.html", error: error)
        end
    end
  end

  def create(conn, params) do
    conn.assigns[:current_user]
    |> Authorization.authorize(params, [otp_app: :glimesh])
    |> redirect_or_render(conn)
  end

  def delete(conn, params) do
    conn.assigns[:current_user]
    |> Authorization.deny(params, [otp_app: :glimesh])
    |> redirect_or_render(conn)
  end

  def show(conn, %{"code" => code}) do
    render(conn, "show.html", code: code)
  end

  defp redirect_or_render({:redirect, redirect_uri}, conn) do
    redirect(conn, external: redirect_uri)
  end
  defp redirect_or_render({:native_redirect, payload}, conn) do
    json(conn, payload)
  end
  defp redirect_or_render({:error, error, status}, conn) do
    conn
    |> put_status(status)
    |> json(error)
  end
end
