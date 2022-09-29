defmodule GlimeshWeb.Plugs.Interactive do
  @moduledoc """
  This plug helps to serve the interactive project files
  See InteractiveController
  """
  use Plug.Builder

  # Serves from the uploads/interactive directory
  plug Plug.Static,
    at: "/interactive",
    from: "uploads/interactive"
end
