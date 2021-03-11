defmodule Glimesh.Configurations.Configuration do
  @moduledoc false

  use Ecto.Schema

  schema "configurations" do
    field :key, :string
    field :value, :string

    timestamps()
  end
end
