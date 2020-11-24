defmodule Glimesh.Accounts.UserSetting do
  @moduledoc false

  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  schema "user_settings" do
    belongs_to :user, Glimesh.Accounts.User

    field :light_mode, :boolean, default: false

    timestamps()
  end

  @doc """
  A changeset for all of the user configurable options
  """
  def changeset(user_setting, attrs) do
    user_setting
    |> cast(attrs, [:light_mode])
  end
end
