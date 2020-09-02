defmodule GlimeshWeb.Plugs.ApiContextPlug do
  @behaviour Plug

  alias ExOauth2Provider.{
    Keys,
    Plug.ErrorHandler
  }
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

  def call(conn, opts) do
    if authorized(conn, opts) do
      context = build_context(conn)
      Absinthe.Plug.put_options(conn, context: context)
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{errors: [%{message: "You must be logged in to access the api"}]})
      |> halt()
    end
  end

  @doc """
  Return the current user context based on the authorization header
  """
  def build_context(conn) do
    # with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
    #      {:ok, current_user} <- authorize(token) do
    #   %{current_user: current_user}
    # else
    #   _ -> %{}
    # end
    if conn.assigns[:current_user] do
      %{current_user: conn.assigns[:current_user]}
    else
      %{}
    end
  end

  def authorized(conn, opts) do
    if get_req_header(conn, "authorization") != [] do
      key    = Keyword.get(opts, :key, :oauth_token)
      config = [otp_app: :glimesh]

      conn
      |> fetch_token(opts)
      |> verify_token(conn, key, config)
      |> get_current_access_token(key)
      |> handle_authentication(conn, key)
    else
      conn.assigns[:current_user]
    end
  end

  defp fetch_token(conn, opts) do
    ["Bearer " <> token] = get_req_header(conn, "authorization")

    token
  end

  defp do_fetch_token(_realm_regex, []), do: nil
  defp do_fetch_token(nil, [token | _tail]), do: String.trim(token)
  defp do_fetch_token(realm_regex, [token | tail]) do
    trimmed_token = String.trim(token)

    case Regex.run(realm_regex, trimmed_token) do
      [_, match] -> String.trim(match)
      _          -> do_fetch_token(realm_regex, tail)
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

  defp handle_authentication({:ok, _}, conn, _opts), do: conn
  defp handle_authentication({:error, reason}, %{params: params} = conn, opts) do
    params = Map.put(params, :reason, reason)

    conn
    |> assign(:ex_oauth2_provider_failure, reason)
    |> halt()
    |> ErrorHandler.unauthenticated(params)
  end

  defp get_current_access_token(conn, the_key) do
    case conn.private[Keys.access_token_key(the_key)] do
      {:ok, access_token} -> {:ok, access_token}
      {:error, error}     -> {:error, error}
      _                   -> {:error, :no_session}
    end
  end
end
