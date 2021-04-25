defmodule Glimesh.Support.GraphqlHelper do
  defmacro run_query(conn, query) do
    quote do
      Phoenix.ConnTest.post(unquote(conn), "/api/graph", %{
        "query" => unquote(query)
      })
      |> Phoenix.ConnTest.json_response(200)
    end
  end

  defmacro run_query(conn, query, variables) do
    quote do
      Phoenix.ConnTest.post(unquote(conn), "/api/graph", %{
        "query" => unquote(query),
        "variables" => unquote(variables)
      })
      |> Phoenix.ConnTest.json_response(200)
    end
  end
end
