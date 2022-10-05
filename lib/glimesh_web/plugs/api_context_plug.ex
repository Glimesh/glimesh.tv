defmodule GlimeshWeb.Plugs.ApiContextPlug do
  @behaviour Plug

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

  def call(conn, opts) do
    case authorize(parse_token_from_header(conn, opts)) do
      {:ok, %Glimesh.Api.Access{} = access} ->
        conn
        |> Absinthe.Plug.put_options(
          context: %{
            access: access
          }
        )

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

  defp authorize({:bearer, token}) do
    case Boruta.Oauth.Authorization.AccessToken.authorize(value: token) do
      {:ok, %Boruta.Oauth.Token{} = token} ->
        Glimesh.Oauth.get_api_access_from_token(token)

      {:error, msg} ->
        {:error, msg}
    end
  end

  defp authorize({:client, client_id}) do
    client_id = Glimesh.OauthMigration.convert_client_id(client_id)

    case Boruta.Ecto.Clients.get_client(client_id) do
      %Boruta.Oauth.Client{} = client ->
        Glimesh.Oauth.get_unprivileged_api_access_from_client(client)

      {:error, msg} ->
        {:error, msg}
    end
  end

  defp authorize(_) do
    {:error, :unauthorized}
  end

  defp parse_token_from_header(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> {:bearer, token}
      ["bearer " <> token] -> {:bearer, token}
      ["Client-ID " <> token] -> {:client, token}
      ["client-id " <> token] -> {:client, token}
      _ -> false
    end
  end
end
