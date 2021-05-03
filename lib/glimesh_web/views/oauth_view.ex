defmodule GlimeshWeb.OauthView do
  use GlimeshWeb, :view

  alias Boruta.Oauth.TokenResponse
  alias Boruta.Oauth.IntrospectResponse

  def render("introspect.json", %{response: %IntrospectResponse{active: false}}) do
    %{"active" => false}
  end

  def render("introspect.json", %{
        response: %IntrospectResponse{
          active: active,
          client_id: client_id,
          username: username,
          scope: scope,
          sub: sub,
          iss: iss,
          exp: exp,
          iat: iat
        }
      }) do
    %{
      active: active,
      client_id: client_id,
      username: username,
      scope: scope,
      sub: String.to_integer(sub),
      iss: iss,
      exp: exp,
      iat: iat
    }
  end

  def render("token.json", %{
        response: %TokenResponse{
          token_type: token_type,
          access_token: access_token,
          expires_in: expires_in,
          refresh_token: refresh_token
        }
      }) do
    %{
      token_type: token_type,
      access_token: access_token,
      expires_in: expires_in,
      refresh_token: refresh_token
    }
  end

  def render("error.json", %{error: error, error_description: error_description}) do
    %{
      error: error,
      error_description: error_description
    }
  end
end
