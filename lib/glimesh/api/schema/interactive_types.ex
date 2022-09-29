defmodule Glimesh.Api.Schema.Types.Interactive do
  @moduledoc """
  The Json scalar type allows arbitrary JSON values to be passed in and out.
  Requires `{ :jason, "~> 1.1" }` package: https://github.com/michalmuskala/jason
  We use this to make sure the user is sending valid json in an interactive message
  """
  use Absinthe.Schema.Notation

  scalar :json, name: "JSON" do
    description("""
    JSON data surrounded by a string.
    "{
      \"test\": 123
    }"
    """)

    serialize(&encode/1)
    parse(&decode/1)
  end

  # Decods the json, returns it if valid. Fails if not
  @spec decode(Absinthe.Blueprint.Input.String.t()) :: {:ok, term()} | :error
  @spec decode(Absinthe.Blueprint.Input.Null.t()) :: {:ok, nil}
  defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
    case Jason.decode(value) do
      {:ok, result} -> {:ok, result}
      _ -> :error
    end
  end

  defp decode(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp decode(_) do
    :error
  end

  defp encode(value), do: value
end
