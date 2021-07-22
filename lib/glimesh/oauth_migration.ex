defmodule Glimesh.OauthMigration do
  @moduledoc """
  A module to help us convert from our old oauth provider to Boruta...
  """
  require Ecto.Query

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

  def token_request(conn) do
    conn
  end

  def convert_client_id(client_id) do
    if Regex.match?(~r/\b[A-Fa-f0-9]{64}\b/, client_id) do
      look_up_uuid(client_id)
    else
      client_id
    end
  end

  def migrate_old_oauth_apps do
    Glimesh.Apps.list_apps()
    |> Enum.each(fn app ->
      case app.oauth_application do
        %Glimesh.OauthApplications.OauthApplication{} = old_app ->
          # Create a Boruta client for each existing oauth application
          {:ok, client} =
            Boruta.Ecto.Admin.create_client(%{
              name: app.name,
              # authorize_scope: old_app.scopes,
              redirect_uris: String.split(old_app.redirect_uri),
              authorization_code_ttl: 60,
              access_token_ttl: 60 * 60
            })

          {:ok, uuid} = Ecto.UUID.dump(client.id)

          # Set the old UID value
          # Overwrite the secret to be the old secret
          Ecto.Query.from("clients",
            where: [id: ^uuid],
            update: [
              set: [secret: ^old_app.secret, old_uid: ^old_app.uid]
            ]
          )
          |> Glimesh.Repo.update_all([])

          # Update the apps table to point to the new values
          Ecto.Query.from("apps",
            where: [id: ^app.id],
            update: [
              set: [client_id: ^uuid]
            ]
          )
          |> Glimesh.Repo.update_all([])

        _ ->
          # Somehow they dont have a real app, skip.
          nil
      end
    end)
  end

  @doc """
  Migrates all currently valid tokens or access tokens to the Boruta tokens table so they can continue to work
  """
  def migrate_existing_tokens(oauth_application_id) do
    Ecto.Query.from("oauth_access_tokens",
      where: [application_id: ^oauth_application_id]
    )
    |> Glimesh.Repo.all()
  end

  def migrate_token(old_token) do
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
    client_id = "foo"
    sub = "user id?"

    new_token = %Boruta.Ecto.Token{
      type: "access_token",
      value: old_token.token,
      refresh_token: old_token.refresh_token,
      expires_at: old_token.inserted_at + old_token.expires_in,
      redirect_uri: nil,
      state: nil,
      scope: old_token.scopes,
      revoked_at: old_token.revoked_at,
      client_id: client_id,
      sub: sub,
      inserted_at: old_token.inserted_at,
      updated_at: NaiveDateTime.utc_now()
    }

    Glimesh.Repo.insert(new_token)
  end

  defp look_up_uuid(old_client_id) do
    query =
      Ecto.Query.from("clients",
        select: [:id],
        where: [old_uid: ^old_client_id]
      )

    case Glimesh.Repo.one(query) do
      %{id: id} ->
        Ecto.UUID.load!(id)

      nil ->
        # By making this blank, the next step which is the validator will reject it.
        ""
    end
  end
end
