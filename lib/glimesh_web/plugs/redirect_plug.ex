defmodule GlimeshWeb.Plugs.Redirect do
  @moduledoc """
  A plug responsible for helping redirect user uploaded assets to a new URL.

  It requires two options:

    * `:from` - the request route to match against
      It must be a string.

    * `:to` - the domain & path to put in front of the request_path.
      It must be a string.
  """
  def init(opts) do
    from =
      case Keyword.fetch!(opts, :from) do
        from when is_binary(from) -> from
        _ -> raise ArgumentError, ":from must be an a binary"
      end

    to =
      case Keyword.fetch!(opts, :to) do
        to when is_binary(to) -> to
        _ -> raise ArgumentError, ":to must be an a binary"
      end

    %{
      from: from,
      to: to
    }
  end

  @doc """
  If we're dealing with a URL that matches the expected from, let's redirect it's request to the to
  """
  def call(%Plug.Conn{request_path: request_path, query_string: query_string} = conn, %{
        from: from,
        to: to
      }) do
    if String.starts_with?(request_path, from) do
      new_url = build_url(to, request_path, query_string)

      conn
      |> Phoenix.Controller.redirect(external: new_url)
      |> Plug.Conn.halt()
    else
      conn
    end
  end

  @doc """
  Pass through any non-matching requests
  """
  def call(conn, _) do
    conn
  end

  defp build_url(to, request_path, "") do
    to |> URI.merge(request_path) |> URI.to_string()
  end

  defp build_url(to, request_path, query_string) do
    to |> URI.merge(request_path) |> URI.merge("?" <> query_string) |> URI.to_string()
  end
end
