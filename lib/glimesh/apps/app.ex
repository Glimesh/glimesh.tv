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
    |> validate_localhost_http_redirect_urls(:redirect_uri)
  end

  def oauth_changset(application, params) do
    ExOauth2Provider.Applications.Application.changeset(application, params, otp_app: :glimesh)
  end

  def validate_localhost_http_redirect_urls(changeset, field) when is_atom(field) do
    changeset
    |> Ecto.Changeset.get_field(field)
    |> Kernel.||("")
    |> String.split()
    |> Enum.reduce(changeset, fn url, changeset ->
      url
      |> validate_localhost_http_url()
      |> case do
        {:error, error} -> Ecto.Changeset.add_error(changeset, :redirect_uri, error)
        {:ok, _} -> changeset
      end
    end)
  end

  def validate_localhost_http_url(url) do
    %URI{host: host, scheme: scheme} = URI.parse(url)

    case [scheme, host] do
      ["http", "localhost"] ->
        {:ok, host}

      ["http", "127.0.0.1"] ->
        {:ok, host}

      ["http", "::1"] ->
        {:ok, host}

      ["https", _] ->
        {:ok, host}

      _ ->
        {:error,
         "If using unsecure http, you must be using a local loopback address like [localhost, 127.0.0.1, ::1]"}
    end
  end
end
