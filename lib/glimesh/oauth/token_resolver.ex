defmodule Glimesh.Oauth.TokenResolver do
  @moduledoc """
  Resolve a token into a user.
  """

  alias Glimesh.Accounts.User
  alias Glimesh.Repo

  @doc """
  Will resolve a token to either a user, or an app.
  """
  def resolve_token(token) do
    with {:error, msg} <- resolve_user(token),
         {:error, msg} <- resolve_app(token) do
      {:error, msg}
    else
      {:ok, something} ->
        {:ok, something}
    end

    cond do
      {:ok, user} = resolve_user(token) ->
        {:ok, user}

      {:ok, app} = resolve_app(token) ->
        {:ok, app}

      true ->
        nil
    end
  end

  def resolve_app(nil) do
    {:error, "No client id specified"}
  end

  def resolve_app(client_id) do
    config = [otp_app: :glimesh]

    ExOauth2Provider.Applications.get_application(client_id, config)
  end

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
