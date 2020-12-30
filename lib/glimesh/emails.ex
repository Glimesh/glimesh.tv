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

  def email_sent_recently?(%User{} = user, filters \\ [], minutes_ago \\ 60) do
    timeframe = NaiveDateTime.add(NaiveDateTime.utc_now(), minutes_ago * 60, :second)
    wheres = Keyword.merge([user_id: user.id], filters)

    Repo.exists?(query_sent_recently(wheres, timeframe))
  end

  def count_emails_sent_recently(%User{} = user, filters \\ [], minutes_ago \\ 60) do
    timeframe = NaiveDateTime.add(NaiveDateTime.utc_now(), minutes_ago * 60, :second)
    wheres = Keyword.merge([user_id: user.id], filters)

    Repo.aggregate(query_sent_recently(wheres, timeframe), :count, :id)
  end

  defp query_sent_recently(wheres, timeframe) do
    from l in EmailLog,
      where: ^wheres,
      where: l.inserted_at < ^timeframe
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
