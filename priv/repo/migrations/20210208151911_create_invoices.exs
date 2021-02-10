defmodule Glimesh.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:subscription_invoices) do
      add :user_id, references(:users)
      add :streamer_id, references(:users)
      add :subscription_id, references(:subscriptions)

      add :stripe_invoice_id, :string
      add :stripe_status, :string
      add :total_amount, :integer

      add :user_paid, :boolean
      add :streamer_paidout, :boolean
      add :streamer_payout_amount, :integer
      add :stripe_transfer_id, :string

      timestamps()
    end

    create unique_index(:subscription_invoices, [:stripe_invoice_id])

    alter table(:users) do
      add :can_receive_payments, :boolean
    end
  end
end
