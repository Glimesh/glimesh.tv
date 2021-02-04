defmodule Glimesh.Accounts.UserPreference do
  @moduledoc false

  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  schema "user_preferences" do
    belongs_to :user, Glimesh.Accounts.User

    field :locale, :string, default: "en"
    field :site_theme, :string, default: "dark"
    field :show_timestamps, :boolean, default: false
    field :show_mature_content, :boolean

    timestamps()
  end

  @doc """
  A changeset for all of the user configurable options
  """
  def changeset(user_preferences, attrs) do
    user_preferences
    |> cast(attrs, [
      :locale,
      :site_theme,
      :show_timestamps,
      :show_mature_content
    ])
  end
end
