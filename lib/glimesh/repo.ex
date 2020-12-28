defmodule Glimesh.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :glimesh,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10

  def data do
    Dataloader.Ecto.new(Glimesh.Repo, query: &query/2)
  end
end
