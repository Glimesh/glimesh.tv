defmodule Glimesh.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :glimesh,
    adapter: Ecto.Adapters.Postgres
end
