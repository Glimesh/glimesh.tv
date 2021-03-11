defmodule Glimesh.Repo.Migrations.AddFeeAndFinalAmount do
  use Ecto.Migration

  import Ecto.Query

  def change do
    alter table(:subscriptions) do
      add :fee, :integer
      add :payout, :integer
    end

    flush()

    from(s in Glimesh.Payments.Subscription, where: not is_nil(s.streamer_id))
    |> Glimesh.Repo.update_all(
      set: [
        fee: 250,
        payout: 250
      ]
    )
  end
end
