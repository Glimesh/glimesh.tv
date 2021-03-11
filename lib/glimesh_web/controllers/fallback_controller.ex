defmodule GlimeshWeb.FallbackController do
  use GlimeshWeb, :controller

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:forbidden)
    |> put_view(GlimeshWeb.ErrorView)
    |> put_flash(:error, "You do not have permission to access this resource.")
    |> render(:"403")
  end
end
