defmodule GlimeshWeb.Plugs.ApiContextPlug do
  @behaviour Plug

  alias Glimesh.Accounts.User

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

  def call(conn, opts) do
    case authorized(conn, opts) do
      {:ok, %User{} = user} ->
        Absinthe.Plug.put_options(conn,
          context: %{
            # Allows us to pattern match admin APIs
            is_admin: user.is_admin,
            current_user: user
          }
        )

      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{errors: [%{message: "You must be logged in to access the api"}]})
        |> halt()
    end
  end

  def authorized(conn, opts) do
    case fetch_token(conn, opts) do
      false -> try_conn(conn, opts)
      token -> try_token(token)
    end
  end

  def try_token(token) do
    Glimesh.Oauth.TokenResolver.resolve_user(token)
  end

  def try_conn(%{assigns: %{current_user: %User{} = current_user}}, _opts) do
    {:ok, current_user}
  end

  def try_conn(_, _opts) do
    {:error, "You are not logged in."}
  end

  defp fetch_token(conn, _opts) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      [] -> false
    end
  end
end
