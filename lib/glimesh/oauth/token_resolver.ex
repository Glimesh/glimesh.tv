defmodule Glimesh.Oauth.TokenResolver do
  @moduledoc """
  Resolve a token into a user.
  """

  alias Glimesh.Accounts.User
  alias Glimesh.Repo

  def resolve_user(nil) do
    {:error, "No token specified"}
  end

  def resolve_user(token) do
    config = [otp_app: :glimesh]

    ExOauth2Provider.authenticate_token(token, config)
    |> handle_authentication()
  end

  defp handle_authentication({:ok, %{resource_owner: %User{} = resource_owner}}) do
    {:ok, resource_owner}
  end

  defp handle_authentication({:ok, %{resource_owner: nil} = oauth_token}) do
    # Slightly more complicated, need to get the app owner when using Client Credentials Grant
    owner =
      oauth_token
      |> Repo.preload(:application)
      |> Map.get(:application)
      |> Repo.preload(:owner)
      |> Map.get(:owner)

    {:ok, owner}
  end

  defp handle_authentication({:error, reason}) do
    {:error, reason}
  end
end
