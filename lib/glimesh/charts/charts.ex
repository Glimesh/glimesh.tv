defmodule Glimesh.Charts do
  @moduledoc false

  defmodule Chart do
    @moduledoc false
    defstruct [:week_date, :streams_new]
  end

  def query_to_struct(query, struct) do
    res =
      Ecto.Adapters.SQL.query!(
        Glimesh.Repo,
        query,
        []
      )

    cols = Enum.map(res.columns, &String.to_atom(&1))

    Enum.map(res.rows, fn row ->
      struct(struct, Enum.zip(cols, row))
    end)
  end
end
