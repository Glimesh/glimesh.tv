defmodule Glimesh.Resolvers.Scopes do
  @moduledoc """
  Glimesh Scopes Policy
  """

  @behaviour Bodyguard.Policy

  alias Glimesh.Accounts.UserAccess

  def authorize(:public, %UserAccess{} = ua, _params), do: ua.public
  def authorize(:email, %UserAccess{} = ua, _params), do: ua.email
  def authorize(:chat, %UserAccess{} = ua, _params), do: ua.chat
  def authorize(:streamkey, %UserAccess{} = ua, _params), do: ua.streamkey

  def authorize(_, _, _), do: false
end
