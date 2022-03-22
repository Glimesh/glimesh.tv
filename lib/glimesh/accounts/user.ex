defmodule Glimesh.Accounts.User do
  @moduledoc false

  use Ecto.Schema
  use Waffle.Ecto.Schema
  import GlimeshWeb.Gettext
  import Ecto.Changeset

  @derive {Inspect, except: [:password, :hashed_password, :tfa_token]}
  schema "users" do
    field :username, :string
    field :displayname, :string
    field :pronoun, :string
    field :show_pronoun_stream, :boolean
    field :show_pronoun_profile, :boolean
    field :email, :string
    field :password, :string, virtual: true
    field :hashed_password, :string
    field :confirmed_at, :naive_datetime

    field :raw_user_ip, :string, virtual: true
    field :user_ip, :string

    field :can_stream, :boolean, default: true

    field :team_role, :string
    field :is_admin, :boolean, default: false
    field :is_gct, :boolean, default: false
    field :gct_level, :integer
    field :is_events_team, :boolean, default: false
    field :is_banned, :boolean, default: false
    field :ban_reason, :string

    field :avatar, Glimesh.Avatar.Type
    field :social_twitter, :string
    field :social_youtube, :string
    field :social_instagram, :string
    field :social_discord, :string
    field :social_guilded, :string

    field :can_payments, :boolean, default: true
    field :is_stripe_setup, :boolean, default: false
    field :is_tax_verified, :boolean, default: false
    field :tax_withholding_percent, :decimal

    field :stripe_user_id, :string
    field :stripe_customer_id, :string
    field :stripe_payment_method, :string

    field :youtube_intro_url, :string
    field :profile_content_md, :string
    field :profile_content_html, :string

    field :tfa_token, :string

    field :allow_glimesh_newsletter_emails, :boolean, default: false
    field :allow_live_subscription_emails, :boolean, default: true

    field :privacy_policy_version, :naive_datetime, default: ~N[2021-02-25 15:17:00]

    has_one :channel, Glimesh.Streams.Channel
    has_one :user_preference, Glimesh.Accounts.UserPreference

    has_many :socials, Glimesh.Accounts.UserSocial
    has_many :followers, Glimesh.AccountFollows.Follower, foreign_key: :streamer_id
    has_many :following, Glimesh.AccountFollows.Follower, foreign_key: :user_id

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
    |> cast(attrs, [
      :username,
      :email,
      :password,
      :raw_user_ip,
      :displayname,
      :allow_glimesh_newsletter_emails,
      :is_admin,
      :can_stream,
      :can_payments,
      :is_stripe_setup,
      :is_banned,
      :is_gct,
      :gct_level,
      :tfa_token
    ])
    |> validate_username()
    |> validate_email()
    |> validate_password()
    |> prepare_changes(&encrypt_user_ip/1)
    |> cast_assoc(:user_preference,
      required: true,
      with: &Glimesh.Accounts.UserPreference.changeset/2
    )
  end

  def notifications_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :allow_glimesh_newsletter_emails,
      :allow_live_subscription_emails
    ])
  end

  def privacy_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :privacy_policy_version
    ])
  end

  defp validate_username(changeset) do
    changeset
    |> validate_required([:username])
    # It's important to make sure username's cannot look like emails, so don't allow @'s
    |> validate_format(:username, ~r/^(?![_.])(?!.*[_.]{2})[a-zA-Z0-9._]+(?<![_.])$/i,
      message: "Use only alphanumeric characters, no spaces"
    )
    |> validate_length(:username, min: 3, max: 24)
    |> unsafe_validate_unique(:username, Glimesh.Repo)
    |> unique_constraint(:username)
    |> validate_username_reserved_words(:username)
    |> validate_username_no_bad_words(:username)

    # Disabled for now
    # |> validate_username_contains_no_bad_words(:username)
  end

  def validate_username_reserved_words(changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn current_field, value ->
      if Enum.member?(Application.get_env(:glimesh, :reserved_words), String.downcase(value)) do
        [{current_field, "This username is reserved"}]
      else
        []
      end
    end)
  end

  def validate_username_no_bad_words(changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn current_field, value ->
      if Enum.member?(Application.get_env(:glimesh, :bad_words), String.downcase(value)) do
        [{current_field, "This username contains a bad word"}]
      else
        []
      end
    end)
  end

  def validate_username_contains_no_bad_words(changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn current_field, value ->
      # credo:disable-for-next-line
      if Enum.any?(Application.get_env(:glimesh, :bad_words), fn w ->
           String.contains?(String.downcase(value), w)
         end) do
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

  defp encrypt_user_ip(changeset) do
    raw_user_ip = get_change(changeset, :raw_user_ip)
    secret = Application.get_env(:glimesh, GlimeshWeb.Endpoint)[:secret_key_base]

    changeset
    |> put_change(:user_ip, Phoenix.Token.encrypt(GlimeshWeb.Endpoint, secret, raw_user_ip))
    |> delete_change(:raw_user_ip)
  end

  def validate_displayname(changeset) do
    validate_change(changeset, :displayname, fn current_field, value ->
      if String.downcase(value) !== String.downcase(get_field(changeset, :username)) do
        [{current_field, gettext("Display name must match Username")}]
      else
        []
      end
    end)
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
      %{} = changeset -> add_error(changeset, :email, gettext("Email is the same"))
    end
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: gettext("Password does not match"))
    |> validate_password()
  end

  @doc """
  A user changeset for changing the password.
  """
  def profile_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :displayname,
      :pronoun,
      :show_pronoun_stream,
      :show_pronoun_profile,
      :social_twitter,
      :social_youtube,
      :social_instagram,
      :social_discord,
      :social_guilded,
      :youtube_intro_url,
      :profile_content_md
    ])
    |> validate_length(:profile_content_md, max: 8192)
    |> validate_required(:displayname)
    |> validate_youtube_url(:youtube_intro_url)
    |> validate_displayname()
    |> strip_discord_invite()
    |> set_profile_content_html()
    |> cast_attachments(attrs, [:avatar])
  end

  def gct_user_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :displayname,
      :username,
      :email,
      :is_admin,
      :can_stream,
      :stripe_user_id,
      :stripe_customer_id,
      :stripe_payment_method,
      :is_stripe_setup,
      :is_tax_verified,
      :tax_withholding_percent,
      :tfa_token,
      :is_banned,
      :ban_reason,
      :can_payments,
      :is_gct,
      :gct_level,
      :team_role,
      :is_events_team
    ])
    |> validate_length(:ban_reason, max: 8192)
    |> validate_username()
    |> validate_email()
  end

  @doc """
  A user changeset for changing the stripe.
  """
  def stripe_changeset(user, attrs) do
    user
    |> cast(attrs, [
      :stripe_customer_id,
      :stripe_user_id,
      :stripe_payment_method,
      :is_stripe_setup,
      :is_tax_verified,
      :tax_withholding_percent
    ])
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  def user_ip_changeset(user, ip_address) do
    change(user)
    |> put_change(:raw_user_ip, ip_address)
    |> prepare_changes(&encrypt_user_ip/1)
  end

  @doc """
  A user changeset for setting 2FA
  """
  def tfa_changeset(user, attrs) do
    user
    |> cast(attrs, [:tfa_token])
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
      add_error(changeset, :current_password, gettext("Invalid Password"))
    end
  end

  def validate_youtube_url(changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn current_field, value ->
      matches = Regex.run(~r/.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=)([^#\&\?]*).*/, value)

      if matches < 2 do
        [{current_field, gettext("Incorrect YouTube URL format")}]
      else
        []
      end
    end)
  end

  def set_profile_content_html(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{profile_content_md: profile_content_md}} ->
        case Glimesh.Accounts.Profile.safe_user_markdown_to_html(profile_content_md) do
          {:ok, content} ->
            put_change(changeset, :profile_content_html, content)

          {:error, message} ->
            add_error(changeset, :profile_content_md, message)
        end

      _ ->
        changeset
    end
  end

  @doc """
  Validates the sent 2FA code otherwise adds an error to the changeset.
  """
  def validate_tfa(changeset, pin, secret) do
    if Glimesh.Tfa.validate_pin(pin, secret) do
      changeset
    else
      add_error(changeset, :tfa, "Invalid 2FA code")
    end
  end

  def strip_discord_invite(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{social_discord: social_discord}} ->
        case Glimesh.Accounts.Profile.strip_invite_link_from_discord_url(social_discord) do
          {:ok, maybe_invite_code} ->
            put_change(changeset, :social_discord, maybe_invite_code)

          {:error, _message} ->
            add_error(changeset, :social_discord, gettext("Invalid Discord invite URL"))
        end

      _ ->
        changeset
    end
  end
end
