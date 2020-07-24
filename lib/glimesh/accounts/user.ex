defmodule Glimesh.Accounts.User do
  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  @derive {Inspect, except: [:password]}
  schema "users" do
    field :username, :string
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime

    field :can_stream, :boolean, default: false
    field :is_admin, :boolean, default: false

    field :avatar, Glimesh.Avatar.Type
    field :social_twitter, :string
    field :social_youtube, :string
    field :social_instagram, :string
    field :social_discord, :string

    timestamps()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both e-mail and password.
  Otherwise databases may truncate the e-mail without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password])
    |> validate_username()
    |> validate_email()
    |> validate_password()
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    |> validate_format(:username, ~r/^(?![_.])(?!.*[_.]{2})[a-zA-Z0-9._]+(?<![_.])$/i)
    |> validate_length(:username, min: 3, max: 50)
    |> unsafe_validate_unique(:username, Glimesh.Repo)
    |> unique_constraint(:username)
    |> validate_username_reserved_words(:username)
    |> validate_username_no_bad_words(:username)
    # Disabled for now
    # |> validate_username_contains_no_bad_words(:username)
  end

  def validate_username_reserved_words(changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn (current_field, value) ->
      if Enum.member?(Application.get_env(:glimesh, :reserved_words), value) do
        [{current_field, "This username is reserved"}]
      else
        []
      end
    end)
  end

  def validate_username_no_bad_words(changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn (current_field, value) ->
      if Enum.member?(Application.get_env(:glimesh, :bad_words), value) do
        [{current_field, "This username contains a bad word"}]
      else
        []
      end
    end)
  end

  def validate_username_contains_no_bad_words(changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn (current_field, value) ->
      if Enum.any?(Application.get_env(:glimesh, :bad_words), fn w -> String.contains?(value, w) end) do
        [{current_field, "This username contains a bad word"}]
      else
        []
      end
    end)
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, Glimesh.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 8, max: 80)
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> prepare_changes(&hash_password/1)
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    changeset
    |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
    |> delete_change(:password)
  end

  @doc """
  A user changeset for changing the e-mail.

  It requires the e-mail to change otherwise an error is added.
  """
  def email_changeset(user, attrs) do
    user
    |> cast(attrs, [:email])
    |> validate_email()
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "Email is the same")
    end
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "Password doesn\'t match")
    |> validate_password()
  end

  @doc """
  A user changeset for changing the password.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [:social_twitter, :social_youtube, :social_instagram, :social_discord])
    |> cast_attachments(attrs, [:avatar])
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%Glimesh.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "Invalid Password")
    end
  end
end
