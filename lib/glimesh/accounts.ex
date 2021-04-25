defmodule Glimesh.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false

  alias Glimesh.Avatar
  alias Glimesh.Accounts.{User, UserNotifier, UserPreference, UserToken}
  alias Glimesh.Repo

  ## Database getters

  def list_users, do: Repo.all(query_users())

  def query_users do
    User
    |> where([u], u.is_banned == false)
  end

  def count_users do
    Repo.one!(from u in User, select: count(u.id), where: u.is_banned == false)
  end

  def search_users(query, current_page, per_page) do
    like = "%#{query}%"

    Repo.all(
      from u in User,
        where: ilike(u.username, ^like),
        where: u.is_banned == false,
        order_by: [asc: u.id],
        offset: ^((current_page - 1) * per_page),
        limit: ^per_page
    )
  end

  def list_admins do
    Repo.all(from u in User, where: u.is_admin == true)
  end

  def list_team_users do
    Repo.all(
      from u in User,
        where: not is_nil(u.team_role),
        order_by: [asc: u.username]
    )
  end

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by username.

  ## Examples

      iex> get_by_username!("foo")
      %User{}

      iex> get_by_username!("unknown")
      nil

  """
  def get_by_username(username, ignore_banned \\ false) when is_binary(username) do
    case ignore_banned do
      false -> Repo.get_by(User, username: username, is_banned: false)
      true -> Repo.get_by(User, username: username)
    end
  end

  def get_by_username!(username, ignore_banned \\ false) when is_binary(username) do
    case ignore_banned do
      false -> Repo.get_by!(User, username: username, is_banned: false)
      true -> Repo.get_by!(User, username: username)
    end
  end

  @doc """
  Gets a user by email or username and verify password.

  ## Examples

      iex> get_user_by_login_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_login_and_password("some_username", "correct_password")
      %User{}

      iex> get_user_by_login_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_login_and_password(login, password)
      when is_binary(login) and is_binary(password) do
    user = Repo.one(from u in User, where: u.email == ^login or u.username == ^login)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)
  def get_user(id), do: Repo.get(User, id)

  def is_user_banned?(%User{} = user), do: user.is_banned

  def is_user_banned_by_username?(username) do
    user = Repo.get_by(User, username: username)
    user.is_banned
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs, existing_preferences \\ %UserPreference{}) do
    # Check to see if the register_user function was called from a test or the live site
    attrs =
      cond do
        attrs["username"] -> Map.merge(attrs, %{"displayname" => attrs["username"]})
        attrs[:username] -> Map.merge(attrs, %{displayname: attrs[:username]})
        true -> attrs
      end

    user_insert =
      %User{
        user_preference: existing_preferences
      }
      |> User.registration_changeset(attrs)
      |> Repo.insert()

    user_insert
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs)
  end

  ## Settings

  def change_user_notifications(%User{} = user, attrs \\ %{}) do
    User.notifications_changeset(user, attrs)
  end

  def update_user_notifications(%User{} = user, attrs \\ %{}) do
    change_user_notifications(user, attrs)
    |> Repo.update()
  end

  def get_user_preference!(%User{} = user) do
    Repo.get_by!(UserPreference, user_id: user.id)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing user's preference.
  """
  def change_user_preference(%UserPreference{} = user_preference, attrs \\ %{}) do
    UserPreference.changeset(user_preference, attrs)
  end

  @doc """
  Updates a users preference
  """
  def update_user_preference(%UserPreference{} = user_preference, attrs \\ %{}) do
    user_preference
    |> UserPreference.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user e-mail.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs)
  end

  @doc """
  Emulates that the e-mail will change without actually changing
  it in the database.

  ## Examples

      iex> apply_user_email(user, "valid password", %{email: ...})
      {:ok, %User{}}

      iex> apply_user_email(user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_user_email(user, password, attrs) do
    user
    |> User.email_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the user e-mail in token.

  If the token matches, the user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
         %UserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(user_email_multi(user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp user_email_multi(user, email, context) do
    changeset = user |> User.email_changeset(%{email: email}) |> User.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, [context]))
  end

  @doc """
  Delivers the update e-mail instructions to the given user.

  ## Examples

      iex> deliver_update_email_instructions(user, current_email, &Routes.user_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the users profile.

  ## Examples

      iex> change_user_profile(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_profile(user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_profile(user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  catch
    :exit, _ ->
      {:upload_exit, "Failed to upload avatar"}
  end

  @doc """
  Gets or creates the user's stripe_customer_id.
  """
  def get_stripe_customer_id(user) do
    case user.stripe_customer_id do
      nil ->
        new_customer = %{
          email: user.email,
          description: user.username
        }

        {:ok, stripe_customer} = Stripe.Customer.create(new_customer)

        {:ok, _} =
          user
          |> User.stripe_changeset(%{stripe_customer_id: stripe_customer.id})
          |> Repo.update()

        stripe_customer.id

      stripe_customer_id ->
        stripe_customer_id
    end
  end

  def set_stripe_attrs(%User{} = user, attrs \\ %{}) do
    user
    |> User.stripe_changeset(attrs)
    |> Repo.update()
  end

  def get_user_by_stripe_user_id(user_id) do
    Repo.one(from u in User, where: u.stripe_user_id == ^user_id)
  end

  def set_stripe_user_id(user, user_id) do
    user
    |> User.stripe_changeset(%{stripe_user_id: user_id})
    |> Repo.update()
  end

  def change_stripe_default_payment(%User{} = user, attrs \\ %{}) do
    User.stripe_changeset(user, attrs)
  end

  def set_stripe_default_payment(user, default_payment) do
    user
    |> User.stripe_changeset(%{stripe_payment_method: default_payment})
    |> Repo.update()
  end

  def change_tfa(user, attrs \\ %{}) do
    User.tfa_changeset(user, attrs)
  end

  def update_tfa(user, pin, password, attrs) do
    changeset =
      case password != "" do
        true ->
          user
          |> User.tfa_changeset(attrs)
          |> User.validate_current_password(password)
          |> User.validate_tfa(pin, attrs.tfa_token)

        false ->
          user
          |> User.tfa_changeset(attrs)
          |> User.validate_tfa(pin, user.tfa_token)
      end

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  def update_user_ip(user, ip_address) do
    user
    |> User.user_ip_changeset(ip_address)
    |> Repo.update()
  end

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) when is_nil(token), do: nil

  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation e-mail instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &Routes.user_confirmation_url(conn, :confirm, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_user_confirmation_instructions(confirmed_user, &Routes.user_confirmation_url(conn, :confirm, &1))
      {:error, :already_confirmed}

  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password e-mail to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &Routes.user_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.

  ## Examples

      iex> get_user_by_reset_password_token("validtoken")
      %User{}

      iex> get_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def can_stream?(user), do: user.can_stream

  def avatar_url(%User{} = user) when is_binary(user.avatar) do
    if String.starts_with?(user.avatar, ["http://", "https://"]) do
      Avatar.url({user.avatar, user})
    else
      GlimeshWeb.Router.Helpers.static_url(
        GlimeshWeb.Endpoint,
        Avatar.url({user.avatar, user})
      )
    end
  end

  def avatar_url(%User{} = user) do
    Avatar.url({user.avatar, user})
  end

  def can_use_payments?(user) do
    user.can_payments
  end

  def can_receive_payments?(user) do
    user.is_stripe_setup && user.is_tax_verified
  end

  def get_user_locale(%User{} = user) do
    prefs = get_user_preference!(user)
    prefs.locale
  end

  def ban_user(%User{} = admin, %User{} = user, reason) do
    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam, :can_ban, admin, user) do
      case reason do
        # Doesn't actually do anything since the ban popup doesn't handle errors. Will eventually do something.
        # For now it just stops the ban going through if the reason is blank.
        "" ->
          throw_error_on_action(
            "Ban reason required",
            %{is_banned: true, ban_reason: reason},
            :ban
          )

        _ ->
          user
          |> User.gct_user_changeset(%{is_banned: true, ban_reason: reason})
          |> Repo.update()
      end
    end
  end

  def unban_user(%User{} = admin, %User{} = user) do
    with :ok <- Bodyguard.permit(Glimesh.CommunityTeam, :can_ban, admin, user) do
      user
      |> User.gct_user_changeset(%{is_banned: false, ban_reason: nil})
      |> Repo.update()
    end
  end

  defp throw_error_on_action(error_message, attrs, action) do
    {:error,
     %Ecto.Changeset{
       action: action,
       changes: attrs,
       errors: [
         message: {error_message, [validation: :required]}
       ],
       data: %User{},
       valid?: false
     }}
  end
end
