defmodule Glimesh.Streams.HmacKey do
  @alphabet Enum.concat([?0..?9, ?A..?Z, ?a..?z])

  def generate_key(length \\ 64) do
    Stream.repeatedly(&rand_char/0)
    |> Enum.take(length)
    |> List.to_string()
  end

  defp rand_char() do
    Enum.random(@alphabet)
  end
end
