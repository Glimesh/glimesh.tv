defmodule GlimeshWeb.Plugs.ApiContextPlug do
  @behaviour Plug

  alias ExOauth2Provider.{
    Keys,
    Plug.ErrorHandler
  }

  alias Glimesh.Accounts.User
  alias Glimesh.Repo

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
    if fetch_token(conn, opts) do
      try_token(conn, opts)
    else
      try_conn(conn, opts)
    end
  end

  def try_token(conn, opts) do
    key = Keyword.get(opts, :key, :oauth_token)
    config = [otp_app: :glimesh]

    conn
    |> fetch_token(opts)
    |> verify_token(conn, key, config)
    |> get_current_access_token(key)
    |> handle_authentication(conn, key)
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

  defp verify_token(nil, conn, _, _config), do: conn
  defp verify_token("", conn, _, _config), do: conn

  defp verify_token(token, conn, key, config) do
    access_token = ExOauth2Provider.authenticate_token(token, config)

    set_current_access_token(conn, access_token, key)
  end

  defp set_current_access_token(conn, access_token, the_key) do
    put_private(conn, Keys.access_token_key(the_key), access_token)
  end

  defp handle_authentication({:ok, %{resource_owner: %User{} = resource_owner}}, _conn, _opts) do
    {:ok, resource_owner}
  end

  defp handle_authentication({:ok, %{resource_owner: nil} = oauth_token}, _conn, _opts) do
    # Slightly more complicated, need to get the app owner when using Client Credentials Grant
    owner =
      oauth_token
      |> Repo.preload(:application)
      |> Map.get(:application)
      |> Repo.preload(:owner)
      |> Map.get(:owner)

    {:ok, owner}
  end

  defp handle_authentication({:error, reason}, %{params: params} = conn, _opts) do
    params = Map.put(params, :reason, reason)

    conn
    |> assign(:ex_oauth2_provider_failure, reason)
    |> halt()
    |> ErrorHandler.unauthenticated(params)

    {:error, reason}
  end

  defp get_current_access_token(conn, the_key) do
    case conn.private[Keys.access_token_key(the_key)] do
      {:ok, access_token} -> {:ok, access_token}
      {:error, error} -> {:error, error}
      _ -> {:error, :no_session}
    end
  end
end
