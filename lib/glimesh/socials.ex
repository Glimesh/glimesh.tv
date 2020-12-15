defmodule Glimesh.Socials do
  @moduledoc """
  The Socials context.
  """

  import Ecto.Query, warn: false
  alias Glimesh.Repo

  alias Glimesh.Accounts.User
  alias Glimesh.Accounts.UserSocial

  # User API Calls
  def get_social(%User{} = user, platform) do
    Repo.one(
      from us in UserSocial,
        where: us.platform == ^platform and us.user_id == ^user.id
    )
  end

  def connected?(%User{} = user, platform) do
    Repo.exists?(
      from us in UserSocial,
        where: us.platform == ^platform and us.user_id == ^user.id
    )
  end

  def connect_user_social(%User{} = user, platform, identifier, username) do
    create_user_social(user, %{
      platform: platform,
      identifier: identifier,
      username: username
    })
  end

  def disconnect_user_social(%User{} = user, platform) do
    get_social(user, platform)
    |> delete_user_social()
  end

  # System API Calls
  defp create_user_social(%User{} = user, attrs) do
    %UserSocial{
      user: user
    }
    |> UserSocial.changeset(attrs)
    |> Repo.insert()
  end

  defp delete_user_social(%UserSocial{} = user_social) do
    user_social
    |> Repo.delete()
  end
end
