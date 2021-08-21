defmodule GlimeshWeb.OauthView do
  use GlimeshWeb, :view

  require Ecto.Query

  alias Boruta.Oauth.IntrospectResponse
  alias Boruta.Oauth.TokenResponse

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
      sub: sub_to_integer(sub),
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
    # Hack to get expiration time
    token =
      Ecto.Query.from("tokens",
        where: [value: ^access_token],
        select: [:inserted_at, :scope],
        limit: 1
      )
      |> Glimesh.Repo.one()

    %{
      token_type: token_type,
      access_token: access_token,
      expires_in: expires_in,
      refresh_token: refresh_token,
      created_at: token.inserted_at,
      scope: token.scope
    }
  end

  def render("error.json", %{error: error, error_description: error_description}) do
    %{
      error: error,
      error_description: error_description
    }
  end

  defp sub_to_integer(sub) when is_binary(sub) do
    String.to_integer(sub)
  end

  defp sub_to_integer(sub) when is_integer(sub) do
    sub
  end

  defp sub_to_integer(_) do
    nil
  end
end
