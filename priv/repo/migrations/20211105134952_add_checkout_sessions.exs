defmodule Glimesh.Repo.Migrations.AddCheckoutSessions do
  use Ecto.Migration

  def change do
    create table(:payables) do
      add :type, :string

      add :user_id, references(:users)
      add :streamer_id, references(:users)

      # Generic fields to allow for any payable configuration
      add :external_source, :string
      add :external_reference, :string
      add :status, :string

      # These fields are calculated by us
      # Cents of course...
      add :total_amount, :integer
      add :external_fees, :integer
      add :our_fees, :integer
      add :withholding_amount, :integer
      add :payout_amount, :integer

      # These fields are what actually happened
      add :user_paid_at, :naive_datetime
      add :streamer_payout_at, :naive_datetime
      add :streamer_payout_amount, :integer
      add :stripe_transfer_id, :string

      timestamps()
    end

    create unique_index(:payables, [:external_source, :external_reference],
             name: :external_source_reference
           )
  end
end
