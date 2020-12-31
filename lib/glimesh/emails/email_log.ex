defmodule Glimesh.Emails.EmailLog do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "email_logs" do
    belongs_to :user, Glimesh.Accounts.User

    field :email, :string
    field :type, :string
    field :function, :string
    field :subject, :string

    timestamps()
  end

  @doc false
  def create_changeset(email_log, attrs) do
    email_log
    |> cast(attrs, [
      :email,
      :type,
      :function,
      :subject
    ])
    |> put_assoc(:user, email_log.user)
    |> validate_required([
      :user,
      :email,
      :type,
      :function,
      :subject
    ])
  end
end
