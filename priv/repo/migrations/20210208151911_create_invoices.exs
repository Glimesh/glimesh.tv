defmodule Glimesh.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:subscription_invoices) do
      add :user_id, references(:users)
      add :streamer_id, references(:users)
      add :subscription_id, references(:subscriptions)

      add :stripe_invoice_id, :string
      add :stripe_status, :string
      # These fields are calculated by us
      add :payout_amount, :integer
      add :withholding_amount, :integer
      add :total_amount, :integer

      # These fields are what actually happened
      add :user_paid, :boolean
      add :streamer_paidout, :boolean
      add :streamer_payout_amount, :integer
      add :stripe_transfer_id, :string

      timestamps()
    end

    create unique_index(:subscription_invoices, [:stripe_invoice_id])

    alter table(:users) do
      add :is_stripe_setup, :boolean, default: false
      add :is_tax_verified, :boolean, default: false
      # default null to prevent division by zero
      add :tax_withholding_percent, :decimal
    end
  end
end
