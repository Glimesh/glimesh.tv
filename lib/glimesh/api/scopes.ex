defmodule Glimesh.Api.Scopes do
  @moduledoc """
  Glimesh Scopes Policy
  """

  @behaviour Bodyguard.Policy

  alias Glimesh.Accounts.User
  alias Glimesh.Accounts.UserAccess

  def authorize(:public, %UserAccess{} = ua, _params), do: ua.public

  def authorize(:email, %UserAccess{} = ua, %User{} = accessing_user) do
    ua.email && ua.user.id == accessing_user.id
  end

  def authorize(:chat, %UserAccess{} = ua, _params), do: ua.chat
  def authorize(:streamkey, %UserAccess{} = ua, _params), do: ua.streamkey

  def authorize(_, _, _), do: false
end
