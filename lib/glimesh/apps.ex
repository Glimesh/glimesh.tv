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
    Repo.all(from a in App, where: a.user_id == ^user.id) |> Repo.preload(:client)
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
  Creates a application for Glimesh, and creates an associated OAuthApplication.

  ## Examples

      iex> create_app(%{field: value})
      {:ok, %App{}}

      iex> create_app(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_app(%User{} = user, attrs \\ %{}) do
    with :ok <- Bodyguard.permit(__MODULE__, :create_app, user) do
      attrs = key_to_atom(attrs)

      case Map.get(Map.get(attrs, :client), :redirect_uris) do
        nil ->
          %App{
            user: user
          }
          |> App.changeset(attrs)
          |> Repo.insert()

        _ ->
          attrs =
            attrs
            |> put_in([:client, :name], Map.get(attrs, :name))
            |> put_in([:client, :access_token_ttl], 60 * 60 * 24)
            |> put_in([:client, :authorization_code_ttl], 60)
            |> put_in(
              [:client, :redirect_uris],
              String.split(
                String.replace(Map.get(Map.get(attrs, :client), :redirect_uris), "\r", ""),
                "\n"
              )
            )

          %App{
            user: user
          }
          |> App.changeset(attrs)
          |> Repo.insert()
      end
    end
  end

  @doc """
  Updates a app.

  ## Examples

      iex> update_app(app, %{field: new_value})
      {:ok, %App{}}

      iex> update_app(app, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_app(%User{} = user, %App{} = app, attrs) do
    with :ok <- Bodyguard.permit(__MODULE__, :update_app, user, app) do
      attrs = key_to_atom(attrs)

      redirect_uris =
        if Map.get(Map.get(attrs, :client), :redirect_uris) do
          String.split(
            String.replace(Map.get(Map.get(attrs, :client), :redirect_uris), "\r", ""),
            "\n"
          )
        else
          app.client.redirect_uris
        end

      attrs =
        attrs
        |> put_in([:client, :id], app.client_id)
        |> put_in([:client, :name], Map.get(attrs, :name))
        |> put_in([:client, :redirect_uris], redirect_uris)

      app
      |> App.changeset(attrs)
      |> Repo.update()
    end
  end

  @doc """
  Rotate public / secret keys for an oauth app.

    ## Examples

      iex> rotate_oauth_app(app)
      {:ok, %ExOauth2Provider.Applications.Application{}}
  """
  def rotate_oauth_app(%User{} = user, %App{} = app) do
    with :ok <- Bodyguard.permit(__MODULE__, :update_app, user, app) do
      # app.client
      # |> Ecto.Changeset.change(%{
      #   uid: ExOauth2Provider.Utils.generate_token(),
      #   secret: ExOauth2Provider.Utils.generate_token()
      # })
      # |> Repo.update()
      {:ok, nil}
    end
  end

  # System API Calls

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
