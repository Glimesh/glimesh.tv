defmodule Glimesh.Apps do
  @moduledoc """
  The Apps context.
  """

  import Ecto.Query, warn: false
  alias Glimesh.Accounts.User
  alias Glimesh.Apps.App
  alias Glimesh.Repo

  defdelegate authorize(action, user, params), to: Glimesh.Apps.Policy

  # User API Calls

  @doc """
  Returns the list of apps for the user.

  ## Examples

      iex> list_apps(%User{})
      [%App{}, ...]

  """
  def list_apps(%User{} = user) do
    Repo.all(from a in App, where: a.user_id == ^user.id)
    |> Repo.preload(:client)
  end

  @doc """
  Gets a single app.

  Raises `Ecto.NoResultsError` if the app does not exist.

  ## Examples

      iex> get_app!(%User{}, 123)
      %App{}

      iex> get_app!(%User{}, 456)
      ** (Ecto.NoResultsError)

  """
  def get_app(%User{} = user, id) do
    app = Repo.get(App, id) |> Repo.preload(:client)

    with :ok <- Bodyguard.permit(__MODULE__, :show_app, user, app) do
      {:ok, app}
    end
  end

  @doc """
  Creates a application for Glimesh, and creates an associated Boruta Client.

  ## Examples

      iex> create_app(%{field: value})
      {:ok, %App{}}

      iex> create_app(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_app(%User{} = user, attrs \\ %{}) do
    with :ok <- Bodyguard.permit(__MODULE__, :create_app, user) do
      attrs = key_to_atom(attrs)

      attrs =
        Map.merge(attrs, %{
          client: %{
            name: attrs.name,
            redirect_uris: String.split(attrs[:client][:redirect_uris] || ""),
            access_token_ttl: 60 * 60 * 24,
            authorization_code_ttl: 60
          }
        })

      %App{
        user: user
      }
      |> App.changeset(attrs, true)
      |> Repo.insert()
    end
  end

  @doc """
  Updates a app, including changes required for the Boruta app.

  ## Examples

      iex> update_app(app, %{field: new_value})
      {:ok, %App{}}

      iex> update_app(app, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_app(%User{} = user, %App{} = app, attrs) do
    with :ok <- Bodyguard.permit(__MODULE__, :update_app, user, app) do
      attrs = key_to_atom(attrs)

      attrs =
        attrs
        |> put_in([:client, :id], app.client.id)
        |> put_in([:client, :name], attrs.name)
        |> put_in([:client, :redirect_uris], String.split(attrs[:client][:redirect_uris] || ""))

      app
      |> App.changeset(attrs, true)
      |> Repo.update()
    end
  end

  @doc """
  Rotate secret keys for an oauth app.
  """
  def rotate_oauth_app(%User{} = user, %App{} = app) do
    with :ok <- Bodyguard.permit(__MODULE__, :update_app, user, app) do
      app.client
      |> Ecto.Changeset.change(%{
        secret: Boruta.TokenGenerator.secret(app.client)
      })
      |> Repo.update()
    end
  end

  @doc """
  Get authorized tokens granted by a user.
  Kinda hacky but boruta doesn't allow this access by default
  """
  def list_valid_tokens_for_user(%Glimesh.Accounts.User{id: user_id}) do
    sub = Integer.to_string(user_id)
    now = DateTime.utc_now() |> DateTime.to_unix()

    Glimesh.Repo.all(
      from t in Boruta.Ecto.Token,
        where:
          t.sub == ^sub and
            is_nil(t.revoked_at) and
            t.expires_at > ^now
    )
    |> Glimesh.Repo.preload(:client)
  end

  def revoke_token_by_id(%Glimesh.Accounts.User{} = user, token_id) do
    token = Glimesh.Repo.get_by(Boruta.Ecto.Token, id: token_id)

    with :ok <- Bodyguard.permit(__MODULE__, :revoke_token, user, token) do
      client = Boruta.Ecto.Admin.get_client!(token.client_id)

      Boruta.Oauth.Revoke.token(%Boruta.Oauth.RevokeRequest{
        client_id: client.id,
        client_secret: client.secret,
        token: token.refresh_token
      })
    end
  end

  # System API Calls

  @doc """
  Gets a single app by Client ID

  ## Examples

      iex> get_app_by_client_id!("1234")
      %App{}

  """
  def get_app_by_client_id!(client_id) do
    Repo.get_by!(App, client_id: client_id) |> Repo.preload(:client)
  end

  def get_app_owner_by_client_id!(client_id) do
    app = Repo.get_by!(App, client_id: client_id) |> Repo.preload(:user)

    app.user
  end

  def get_client_id(%App{} = app) do
    app.client.id
  end

  def get_client_secret(%App{} = app) do
    app.client.secret
  end

  def get_client_redirect_uris(%App{} = app) do
    app.client.redirect_uris
  end

  @doc """
  Returns the list of apps.

  ## Examples

      iex> list_apps()
      [%App{}, ...]

  """
  def list_apps do
    Repo.all(from(a in App)) |> Repo.preload(:client)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking app changes.

  ## Examples

      iex> change_app(app)
      %Ecto.Changeset{data: %App{}}

  """
  def change_app(%App{} = app, attrs \\ %{}) do
    App.changeset(app, attrs)
  end

  # Private Calls

  defp key_to_atom(%Plug.Upload{} = map) do
    map
  end

  defp key_to_atom(map) do
    Enum.reduce(map, %{}, fn
      # String.to_existing_atom saves us from overloading the VM by
      # creating too many atoms. It'll always succeed because all the fields
      # in the database already exist as atoms at runtime.
      {key, value}, acc when is_map(value) and is_atom(key) ->
        Map.put(acc, key, key_to_atom(value))

      {key, value}, acc when is_map(value) and is_binary(key) ->
        Map.put(acc, String.to_existing_atom(key), key_to_atom(value))

      {key, value}, acc when is_atom(key) ->
        Map.put(acc, key, value)

      {key, value}, acc when is_binary(key) ->
        Map.put(acc, String.to_existing_atom(key), value)
    end)
  end
end
