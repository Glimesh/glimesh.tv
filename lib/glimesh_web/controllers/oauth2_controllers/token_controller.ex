defmodule GlimeshWeb.Oauth2Provider.TokenController do
  @moduledoc false
  use GlimeshWeb, :controller

  alias ExOauth2Provider.Token
  alias Glimesh.OauthHandler.TokenUtils

  def create(params) do
    params
    |> Token.grant(otp_app: :glimesh)
  end

  def revoke(params) do
    params
    |> Token.revoke(otp_app: :glimesh)
  end
end
