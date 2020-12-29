defmodule Glimesh.Emails do
  @moduledoc """
  Emails context
  """

  alias Glimesh.Accounts.User
  alias Glimesh.Emails.EmailLog
  alias Glimesh.Repo

  import Ecto.Query, warn: false

  def list_email_log(%User{} = user) do
    Repo.all(
      from l in EmailLog,
        where: l.user_id == ^user.id,
        order_by: [desc: l.inserted_at],
        limit: 50
    )
  end

  def log_bamboo_delivery(bamboo, user, type, function, subject) do
    log_email(user, type, function, subject)

    bamboo
  end

  def log_email(%User{} = user, type, function, subject) do
    %EmailLog{user: user}
    |> EmailLog.create_changeset(%{
      email: user.email,
      type: type,
      function: function,
      subject: subject
    })
    |> Repo.insert()
  end
end
