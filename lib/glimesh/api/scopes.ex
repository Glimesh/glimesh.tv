defmodule Glimesh.Api.Scopes do
  @moduledoc """
  Glimesh Scopes Policy
  """

  @behaviour Bodyguard.Policy

  alias Glimesh.Accounts.User
  alias Glimesh.Api.Access

  def authorize(:public, %Access{} = ua, _params), do: scope_check(ua, :public)

  def authorize(:email, %Access{} = ua, %User{} = accessing_user) do
    scope_check(ua, :email) && ua.user.id == accessing_user.id
  end

  def authorize(:chat, %Access{} = ua, _params), do: scope_check(ua, :chat)
  def authorize(:streamkey, %Access{} = ua, _params), do: scope_check(ua, :streamkey)

  def authorize(:stream_mutations, %Access{is_admin: true}, _params) do
    true
  end

  def authorize(_, _, _), do: false

  defp scope_check(%Access{} = ua, scope) do
    # Verifies the key exists AND is true
    Map.get(ua.scopes, scope, false) == true
  end
end
