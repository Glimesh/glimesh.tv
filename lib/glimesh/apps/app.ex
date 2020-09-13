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
    belongs_to :oauth_application, Glimesh.OauthApplications.OauthApplication

    timestamps()
  end

  @doc """
  Changeset for our own application
  """
  def changeset(app, attrs) do
    app
    |> cast(attrs, [:name, :homepage_url, :description, :logo])
    |> validate_required([:name, :description])
    |> validate_length(:name, min: 3, max: 50)
    |> validate_length(:description, max: 255)
    |> cast_attachments(attrs, [:logo])
    |> cast_assoc(:oauth_application,
      required: true,
      with: &oauth_changset/2
    )
  end

  def oauth_changset(application, %{owner: %Glimesh.Accounts.User{}} = params) do
    # Manually set the owner
    %{application | owner: params.owner}
    |> ExOauth2Provider.Applications.Application.changeset(params, otp_app: :glimesh)
  end

  def oauth_changset(application, params) do
    ExOauth2Provider.Applications.Application.changeset(application, params, otp_app: :glimesh)
  end
end
