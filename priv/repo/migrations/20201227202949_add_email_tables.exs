defmodule Glimesh.Repo.Migrations.AddEmailTables do
  use Ecto.Migration

  def change do
    # This will be a log of every single email sent
    # Type + Function field will be used to ensure no user receives multiple of the same type of
    # email with an interval. An example is they can only get 1 Go Live email per hour.
    create table(:email_logs) do
      add :user_id, references(:users)
      add :email, :string
      add :type, :string
      add :function, :string
      add :subject, :string

      timestamps()
    end

    # Opt-in instead of opt-out :)
    alter table(:users) do
      add :allow_glimesh_newsletter_emails, :boolean, default: false

      # Live Subscription Emails are defaulted to true because you have to opt-in to them indivdiually
      add :allow_live_subscription_emails, :boolean, default: true
    end
  end
end
