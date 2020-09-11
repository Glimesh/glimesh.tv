defmodule GlimeshWeb.Oauth2Provider.AuthorizationController do
  @moduledoc false
  use GlimeshWeb, :controller

  alias Glimesh.OauthHandler

  def new(conn, params) do
    code = Map.get(params, "code")

    if code != nil do
      redirect(conn, to: Routes.authorization_path(conn, :show, code))
    else
      conn.assigns[:current_user]
      |> OauthHandler.preauthorize(params, otp_app: :glimesh)
      |> case do
        {:ok, client, scopes} ->
          render(conn, "new.html",
            params: params,
            client: client |> Glimesh.Repo.preload(:app),
            scopes: scopes
          )

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

  def create(conn, %{"action" => "authorize"} = params) do
    conn.assigns[:current_user]
    |> OauthHandler.authorize(params, otp_app: :glimesh)
    |> redirect_or_render(conn)
  end

  def create(conn, %{"action" => "deny"} = params) do
    conn.assigns[:current_user]
    |> OauthHandler.deny(params, otp_app: :glimesh)
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
    |> render("error.html", error: error)
  end

  defp redirect_or_render({:error, {:error, error, status}}, conn) do
    conn
    |> put_status(status)
    |> render("error.html", error: error)
  end
end
