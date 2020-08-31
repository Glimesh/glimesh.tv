defmodule GlimeshWeb.Oauth2Provider.TokenController do
  @moduledoc false
  use GlimeshWeb, :controller

  alias ExOauth2Provider.Token

  def create(conn, params) do
    params
    |> Token.grant([otp_app: :glimesh])
    |> case do
      {:ok, access_token} ->
        json(conn, access_token)

      {:error, error, status} ->
        conn
        |> put_status(status)
        |> json(error)
    end
  end

  def revoke(conn, params) do
    params
    |> Token.revoke([otp_app: :glimesh])
    |> case do
      {:ok, response} ->
        json(conn, response)

      {:error, error, status} ->
        conn
        |> put_status(status)
        |> json(error)
    end
  end

  def debug(conn, _params) do
    json(conn, Enum.into(Routes.__info__(:functions), %{}, fn {k,v} -> {"#{k}/#{v}", v} end))
  end
end
