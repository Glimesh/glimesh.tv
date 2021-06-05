defmodule GlimeshWeb.Plugs.ApiContextPlug do
  @behaviour Plug

  alias Glimesh.Accounts.User

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

  def call(conn, opts) do
    case authorized(conn, opts) do
      # Allows us to extend to better token support
      {:ok, %Boruta.Oauth.Token{} = token} ->
        check_token(conn, token)

      {:ok, %Glimesh.Accounts.UserAccess{} = user_access} ->
        put_plug(conn, user: user_access.user, access: user_access)

      {:ok, %Boruta.Oauth.Client{id: id}} ->
        put_plug(conn, id: id, type: "new_id")

      {:ok, %Glimesh.OauthApplications.OauthApplication{id: id}} ->
        put_plug(conn, id: id, type: "old_id")

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
      false ->
        try_conn(conn, opts)

      {_, nil} ->
        try_conn(conn, opts)

      {:bearer, token} ->
        res = Boruta.Oauth.Authorization.AccessToken.authorize(value: token)

        case res do
          {:error, _} ->
            Glimesh.Oauth.TokenResolver.resolve_user(token)

          _ ->
            res
        end

      {:client, token} ->
        res = Boruta.Config.clients().get_by(id: token)

        case res do
          nil ->
            Glimesh.Oauth.TokenResolver.resolve_app(token)

          _ ->
            res
        end
    end
  end

  def try_conn(%{assigns: %{current_user: %User{} = current_user}}, _opts) do
    {:ok,
     %Glimesh.Accounts.UserAccess{
       user: current_user,
       public: true,
       email: true,
       chat: true,
       streamkey: true
     }}
  end

  def try_conn(_, _opts) do
    {:error, "You are not logged in."}
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
    case token.resource_owner do
      %Boruta.Oauth.ResourceOwner{} = resource_owner ->
        case Glimesh.Oauth.ResourceOwners.get_from(resource_owner) do
          %User{} = user ->
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
        put_plug(conn, id: token.id)
    end
  end

  defp put_plug(conn, user: user, access: access) do
    Absinthe.Plug.put_options(conn,
      context: %{
        is_admin: user.is_admin,
        current_user: user,
        access_type: "app_token",
        access_identifier: user.username,
        user_access: access
      }
    )
  end

  defp put_plug(conn, id: id, type: type) do
    Absinthe.Plug.put_options(conn,
      context: %{
        is_admin: false,
        current_user: nil,
        access_type: "app_#{type}",
        access_identifier: id,
        user_access: %Glimesh.Accounts.UserAccess{}
      }
    )
  end
end
