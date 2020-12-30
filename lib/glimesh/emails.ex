defmodule Glimesh.Emails do
  @moduledoc """
  Emails context
  """

  alias Glimesh.Accounts.User
  alias Glimesh.Emails.EmailLog
  alias Glimesh.Repo

  import Ecto.Query, warn: false

  @doc """
  List all sent emails for a particular user

  ## Examples

      iex> list_email_log(%User{})
      [%EmailLog{}]

  """
  def list_email_log(%User{} = user) do
    Repo.all(
      from l in EmailLog,
        where: l.user_id == ^user.id,
        order_by: [desc: l.inserted_at],
        limit: 50
    )
  end

  @doc """
  Has the user received any emails recently that match a specific filter

  ## Examples

      iex> email_sent_recently?(%User{}, [subject: "Spammy Email"])
      true

      iex> email_sent_recently?(%User{}, [subject: "Totally normal email"], 30)
      false

  """
  def email_sent_recently?(%User{} = user, filters \\ [], minutes_ago \\ 60) do
    timeframe = NaiveDateTime.add(NaiveDateTime.utc_now(), minutes_ago * 60, :second)
    wheres = Keyword.merge([user_id: user.id], filters)

    Repo.exists?(query_sent_recently(wheres, timeframe))
  end

  @doc """
  How many emails of a certain filter has the user received in x time.

  ## Examples

      iex> count_emails_sent_recently(%User{}, [subject: "Spammy Email"])
      5

      iex> count_emails_sent_recently(%User{}, [subject: "Totally normal email"], 30)
      1
  """
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

  @doc """
  Logs an email, useful for chaining as it always returns the first param.

  ## Examples

      iex>  Mailer.deliver_later(email) |> log_bamboo_delivery(
        user,
        "Account Transactional",
        "user:reset_password_instructions",
        email.subject
      )
      deliver_later_response

  """
  def log_bamboo_delivery(bamboo, user, type, function, subject) do
    log_email(user, type, function, subject)

    bamboo
  end

  @doc """
  Logs an email.

  ## Examples

      iex> list_email_log(%User{})
      {:ok, %EmailLog{}}

  """
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
