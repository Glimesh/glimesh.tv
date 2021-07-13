defmodule Glimesh.OauthMigration do
  @moduledoc """
  A module to help us convert from our old oauth provider to Boruta...
  """

  @doc """
  Convert a token request with a sha256 client_id into Boruta's format using a lookup table
  """
  def token_request(%Plug.Conn{body_params: %{"client_id" => client_id}} = conn) do
    case Regex.match?(~r/\b[A-Fa-f0-9]{64}\b/, client_id) do
      true ->
        found_uuid = "978aa00f-9e1d-4aad-98c1-783ab4356c6f"

        # Plug.Conn has parsed the body at this point, so we need to update both locations
        conn
        |> Map.update(:body_params, %{}, fn e ->
          %{e | "client_id" => found_uuid}
        end)
        |> Map.update(:params, %{}, fn e ->
          %{e | "client_id" => found_uuid}
        end)

      false ->
        conn
    end
  end

  def token_request(conn) do
    conn
  end

  def migrate_old_oauth_apps do
    Glimesh.Apps.list_apps()
    |> Enum.each(fn app ->
      # Create a Boruta client for each existing oauth application
      Boruta.Ecto.Admin.create_client(%{})
    end)
  end
end
