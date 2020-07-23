defmodule Glimesh.Repo do
  use Ecto.Repo,
    otp_app: :glimesh,
    adapter: Ecto.Adapters.Postgres
end
