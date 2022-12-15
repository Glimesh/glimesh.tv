defmodule Glimesh.OauthMigration do
  @moduledoc """
  A module to help us convert from our old oauth provider to Boruta...
  """
  import Ecto.Query

  alias Glimesh.Repo

  @doc """
  Convert a token request with a sha256 client_id into Boruta's format using a lookup table
  """
  def token_request(%Plug.Conn{body_params: %{"client_id" => client_id}} = conn) do
    client_id = convert_client_id(client_id)

    # Plug.Conn has parsed the body at this point, so we need to update both locations
    conn
    |> Map.update(:body_params, %{}, fn e ->
      %{e | "client_id" => client_id}
    end)
    |> Map.update(:params, %{}, fn e ->
      %{e | "client_id" => client_id}
    end)
  end

  def token_request(%Plug.Conn{query_params: %{"client_id" => client_id}} = conn) do
    client_id = convert_client_id(client_id)

    # Plug.Conn has parsed the body at this point, so we need to update both locations
    conn
    |> Map.update(:query_params, %{}, fn e ->
      %{e | "client_id" => client_id}
    end)
    |> Map.update(:params, %{}, fn e ->
      %{e | "client_id" => client_id}
    end)
  end

  def token_request(conn) do
    conn
  end

  @doc """
  Boruta incorrectly uses body_params instead of params, so if we are testing, or they are query params it ends up munging them.
  """
  def patch_body_params(conn) do
    # Boruta uses body_params instead of params, but we want to allow both types
    conn
    |> Map.update(:body_params, %{}, fn e ->
      Map.merge(conn.query_params, e)
    end)
  end

  def convert_client_id(client_id) do
    if Regex.match?(~r/\b[A-Fa-f0-9]{64}\b/, client_id) do
      look_up_uuid(client_id)
    else
      client_id
    end
  end

  def migrate do
    migrate_scopes()
    migrate_old_oauth_apps()
  end

  def migrate_scopes do
    scopes = [
      %{label: "Public", name: "public", public: true},
      %{label: "Email", name: "email", public: true},
      %{label: "Chat", name: "chat", public: true},
      %{label: "Stream Key", name: "streamkey", public: true},
      %{label: "Follow Channel", name: "follow", public: true},
      %{label: "Update Stream Info", name: "stream_info", public: true},
      %{label: "Verify Interactive Messages", name: "interactive", public: true}
    ]

    Enum.each(scopes, fn attrs ->
      Boruta.Ecto.Admin.create_scope(attrs)
    end)
  end

  def migrate_old_oauth_apps do
    Glimesh.Apps.list_apps()
    |> Enum.filter(& &1.oauth_application_id)
    |> Enum.each(fn app ->
      old_app =
        Repo.one(
          from a in "oauth_applications",
            select: %{
              id: a.id,
              name: a.name,
              uid: a.uid,
              secret: a.secret,
              redirect_uri: a.redirect_uri,
              scopes: a.scopes,
              owner_id: a.owner_id,
              inserted_at: a.inserted_at,
              updated_at: a.updated_at
            },
            where: a.id == ^app.oauth_application_id
        )

      # Create a Boruta client for each existing oauth application
      {:ok, client} =
        Boruta.Ecto.Admin.create_client(%{
          name: app.name,
          redirect_uris: String.split(old_app.redirect_uri),
          authorization_code_ttl: 60,
          access_token_ttl: 60 * 60
        })

      {:ok, uuid} = Ecto.UUID.dump(client.id)

      # Set the old UID value
      # Overwrite the secret to be the old secret
      Ecto.Query.from("oauth_clients",
        where: [id: ^uuid],
        update: [
          set: [secret: ^old_app.secret, old_uid: ^old_app.uid]
        ]
      )
      |> Repo.update_all([])

      # Update the apps table to point to the new values
      Ecto.Query.from("apps",
        where: [id: ^app.id],
        update: [
          set: [client_id: ^uuid]
        ]
      )
      |> Repo.update_all([])

      # Migrate all tokens
      migrate_existing_tokens(old_app.id, client.id)
    end)
  end

  @doc """
  Migrates all currently valid tokens or access tokens to the Boruta tokens table so they can continue to work
  """
  def migrate_existing_tokens(oauth_application_id, new_client_id) do
    # We need to migrate:
    # * _all_ non-revoked refresh tokens
    # * Any active access tokens

    # select * from oauth_access_tokens
    # where application_id = 5 and refresh_token is not null and revoked_at is not null;
    # select * from oauth_access_tokens
    # where application_id = 5 and inserted_at + expires_in * interval '1 second' > now() and revoked_at is not null;
    all_non_revoked_refresh_tokens =
      Repo.replica().all(
        from t in "oauth_access_tokens",
          select: %{
            token: t.token,
            refresh_token: t.refresh_token,
            application_id: t.application_id,
            revoked_at: t.revoked_at,
            scopes: t.scopes,
            resource_owner_id: t.resource_owner_id,
            application_id: t.application_id,
            expires_in: t.expires_in,
            inserted_at: t.inserted_at
          },
          where:
            t.application_id == ^oauth_application_id and is_nil(t.revoked_at) and
              (not is_nil(t.refresh_token) or
                 fragment(
                   "?::timestamp + ? * interval '1 second' > now()",
                   type(t.inserted_at, :string),
                   t.expires_in
                 ))
      )

    Enum.map(all_non_revoked_refresh_tokens, fn token ->
      migrate_token(token, new_client_id)
    end)
  end

  def migrate_token(token, client_id) do
    # Exiting tokens include
    # id                     | 5
    # token                  | 4425bc3e6e2ef54c09a43c1f4fefa5e0d582bf10fc71c74fef271817a8ebd938
    # refresh_token          |
    # expires_in             | 21600
    # revoked_at             |
    # scopes                 | public chat
    # previous_refresh_token |
    # resource_owner_id      |
    # application_id         | 1
    # inserted_at            | 2021-03-25 14:31:41
    # updated_at             | 2021-03-25 14:31:41

    # Mapping:
    # ex_oauth => boruta
    # token => value
    # refresh_token => refresh_token
    # expires_in => expires_at converted to timestamp + expires_in
    # revoked_at => revoked_at
    # scopes => scope
    # previous_refresh_token => Maybe not needed?
    # resource_owner_id => Sub? But we have to manually handle it
    # application_id => Ignored, client ID will take its place
    sub = if token.resource_owner_id, do: Integer.to_string(token.resource_owner_id), else: nil

    expires =
      NaiveDateTime.add(token.inserted_at, token.expires_in, :second)
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.to_unix()

    new_token = %Boruta.Ecto.Token{
      type: "access_token",
      value: token.token,
      refresh_token: token.refresh_token,
      expires_at: expires,
      redirect_uri: nil,
      state: nil,
      scope: token.scopes,
      # Token cannot be revoked
      revoked_at: nil,
      client_id: client_id,
      sub: sub,
      inserted_at: DateTime.from_naive!(token.inserted_at, "Etc/UTC"),
      updated_at: DateTime.utc_now()
    }

    Repo.insert(new_token)
  end

  defp look_up_uuid(old_client_id) do
    query =
      Ecto.Query.from("oauth_clients",
        select: [:id],
        where: [old_uid: ^old_client_id]
      )

    case Repo.one(query) do
      %{id: id} ->
        case Ecto.UUID.load(id) do
          {:ok, uuid} ->
            uuid

          _ ->
            nil
        end

      nil ->
        # By making this blank, the next step which is the validator will reject it.
        ""
    end
  end
end
