defmodule Glimesh.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :glimesh,
    adapter: Ecto.Adapters.Postgres

  def data do
    Dataloader.Ecto.new(Glimesh.Repo, query: &query/2)
  end
end
