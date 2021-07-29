defmodule Glimesh.Oauth do
  @moduledoc """
  Helper functions for resolving oauth actions
  """

  require Logger

  #
  # API Access Resolution
  #
  def get_api_access_from_token(%Boruta.Oauth.Token{} = token) do
    resolve_resource_owner(token.resource_owner, token)
  end

  def get_unprivileged_api_access_from_client(%Boruta.Oauth.Client{} = client) do
    {:ok,
     %Glimesh.Api.Access{
       is_admin: false,
       user: nil,
       access_type: "app",
       access_identifier: client.id
     }}
  end

  defp resolve_resource_owner(
         %Boruta.Oauth.ResourceOwner{} = resource_owner,
         %Boruta.Oauth.Token{} = token
       ) do
    case Glimesh.Oauth.ResourceOwners.get_from(resource_owner) do
      %Glimesh.Accounts.User{} = user ->
        access_for_user(user, token.scope)

      _ ->
        Logger.error("Unexpected resource owner for token: #{token.value}")
        {:error, "Unexpected resource owner for token: #{token.value}"}
    end
  end

  defp resolve_resource_owner(_, %Boruta.Oauth.Token{} = token) do
    owner = Glimesh.Apps.get_app_owner_by_client_id!(token.client.id)

    access_for_user(owner, token.scope)
  end

  def access_for_user(%Glimesh.Accounts.User{} = user, scope) do
    {:ok,
     Map.merge(
       %Glimesh.Api.Access{
         is_admin: user.is_admin,
         user: user,
         access_type: "user",
         access_identifier: user.username
       },
       parse_scope(scope)
     )}
  end

  defp parse_scope(scope) when is_binary(scope) do
    %{
      scopes:
        Enum.reduce(String.split(scope), %{}, fn x, acc ->
          Map.put(acc, String.to_atom(x), true)
        end)
    }
  end

  defp parse_scope(_) do
    %{}
  end
end
