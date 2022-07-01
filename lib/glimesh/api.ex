defmodule Glimesh.Api do
  @moduledoc """
  The Glimesh API uses GraphQL endpoints to serve data. Mostly intended for 3rd party clients and our mobile app.
  """
  alias Absinthe.Relay.Connection
  alias Glimesh.Repo

  defmodule Access do
    @moduledoc """
    Common struct for ensuring API access
    """
    defstruct is_admin: false,
              user: nil,
              access_type: nil,
              access_identifier: nil,
              scopes: %{
                public: false,
                email: false,
                chat: false,
                streamkey: false,
                follow: false,
                stream_info: false
              }
  end

  @error_not_found "Could not find resource"
  @error_access_denied "Access denied"

  def error_not_found, do: {:error, @error_not_found}

  def error_access_denied, do: {:error, @error_access_denied}

  @doc """
  Return a Connection.from_query with a count (if last is specified).
  """
  def connection_from_query_with_count(query, args, options \\ []) do
    options =
      if Map.has_key?(args, :last) do
        # Only count records if we're starting at the end
        Keyword.put(options, :count, Repo.aggregate(query, :count, :id))
      else
        options
      end

    # Set a complete max of 1000 records
    options = Keyword.put(options, :max, 1000)

    # If the user didn't select an order, just give them the first 100
    args =
      if Map.has_key?(args, :first) == false and Map.has_key?(args, :last) == false do
        Map.put(args, :first, 100)
      else
        args
      end

    Connection.from_query(query, &Repo.replica().all/1, args, options)
  end

  @doc """
  Parse a list of changeset errors into actionable API errors
  """
  def parse_ecto_changeset_errors(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {key, value} -> "#{key}: #{value}" end)
  end

  @doc """
  If a potentially_local_path is a locally uploaded Waffle file (for example a default chat background),
  this function will create a full static URL for us to return to the API. If the potentially_local_path is
  instead a full URL, we'll just return it.
  """
  def resolve_full_url(potentially_local_path) when is_binary(potentially_local_path) do
    if String.starts_with?(potentially_local_path, ["http://", "https://"]) do
      potentially_local_path
    else
      GlimeshWeb.Router.Helpers.static_url(
        GlimeshWeb.Endpoint,
        potentially_local_path
      )
    end
  end

  def resolve_full_url(_), do: nil
end
