defmodule GlimeshWeb.Plugs.ApiContextPlug do
  @behaviour Plug

  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def init(opts), do: opts

  def call(conn, _) do
    if authorized(conn) do
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

  def authorized(conn) do
    conn.assigns[:current_user]
  end
end
