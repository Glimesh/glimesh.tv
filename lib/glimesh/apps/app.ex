defmodule Glimesh.Apps.App do
  @moduledoc false

  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  schema "apps" do
    field :name, :string
    field :homepage_url, :string
    field :description, :string
    field :logo, Glimesh.AppLogo.Type

    belongs_to :user, Glimesh.Accounts.User
    has_one :oauth_application, Glimesh.OauthApplications.OauthApplication

    timestamps()
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:name, :homepage_url, :description, :logo])
    |> validate_required([:name, :description])
    |> cast_attachments(attrs, [:logo])
  end
end
