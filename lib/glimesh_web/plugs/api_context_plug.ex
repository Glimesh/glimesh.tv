defmodule GlimeshWeb.Plugs.ApiContextPlug do
  @behaviour Plug

  alias Glimesh.OauthApplications.OauthApplication

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

  def call(conn, opts) do
    case authorized(conn, opts) do
      {:ok, %Boruta.Oauth.Token{} = token} ->
        check_token(conn, token)

      {:ok, %Glimesh.Accounts.UserAccess{} = user_access} ->
        put_plug(conn, user: user_access.user, access: user_access)

      {:ok, %Boruta.Oauth.Client{id: id}} ->
        put_plug(conn, id: id)

      {:error, %Boruta.Oauth.Error{} = reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          errors: [
            %{
              message: reason.error_description,
              header_error: reason.error
            }
          ]
        })
        |> halt()

      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{errors: [%{message: "You must be logged in to access the api"}]})
        |> halt()
    end
  end

  def authorized(conn, opts) do
    case fetch_token(conn, opts) do
      {:bearer, token} ->
        Boruta.Oauth.Authorization.AccessToken.authorize(value: token)

      {:client, original_client_id} ->
        # Conver the Client ID if needed to the boruta ID
        client_id = Glimesh.OauthMigration.convert_client_id(original_client_id)
        Boruta.Config.clients().get_by(id: client_id)

      _ ->
        {:error, :unauthorized}
    end
  end

  defp fetch_token(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:bearer, token}
      ["bearer " <> token] -> {:bearer, token}
      ["Client-ID " <> token] -> {:client, token}
      ["client-id " <> token] -> {:client, token}
      _ -> false
    end
  end

  defp check_token(conn, token) do
    IO.inspect(token, label: "token")

    case token.resource_owner do
      %Boruta.Oauth.ResourceOwner{} = resource_owner ->
        case Glimesh.Oauth.ResourceOwners.get_from(resource_owner) do
          %Glimesh.Accounts.User{} = user ->
            put_plug(conn,
              user: user,
              access: Glimesh.Oauth.Scopes.get_user_access(token.scope, user)
            )

          _ ->
            conn
            |> put_status(:unauthorized)
            |> json(%{errors: [%{message: "You must be logged in to access the api"}]})
            |> halt()
        end

      _ ->
        # This is a fallback for whenever the token is not granted for a specific user and is instead a client_credential or similar. I'm not sure this is the fallback we expect? Or if it is, we need to attach the app owners UserAccess to it.
        put_plug(conn, id: token.id)
    end
  end

  defp put_plug(conn, user: user, access: access) do
    Absinthe.Plug.put_options(conn,
      context: %{
        is_admin: user.is_admin,
        current_user: user,
        access_type: "user_token",
        access_identifier: user.username,
        user_access: access
      }
    )
  end

  defp put_plug(conn, id: id) do
    Absinthe.Plug.put_options(conn,
      context: %{
        is_admin: false,
        current_user: nil,
        access_type: "app_id",
        access_identifier: id,
        user_access: %Glimesh.Accounts.UserAccess{}
      }
    )
  end
end
