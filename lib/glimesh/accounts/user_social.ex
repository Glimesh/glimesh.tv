defmodule Glimesh.Accounts.UserSocial do
  @moduledoc false

  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  schema "user_socials" do
    belongs_to :user, Glimesh.Accounts.User

    field :platform, :string
    field :identifier, :string
    field :username, :string

    timestamps()
  end

  @doc """
  A changeset for user socials
  """
  def changeset(user_socials, attrs) do
    user_socials
    |> cast(attrs, [
      :platform,
      :identifier,
      :username
    ])
    |> unique_constraint([:platform, :identifier])
  end
end
