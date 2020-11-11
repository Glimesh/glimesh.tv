defmodule GlimeshWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use GlimeshWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import GlimeshWeb.ConnCase

      alias GlimeshWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint GlimeshWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Glimesh.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Glimesh.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in users.

      setup :register_and_log_in_user

  It stores an updated connection and a registered user in the
  test context.
  """
  def register_and_log_in_user(%{conn: conn}) do
    user = Glimesh.AccountsFixtures.user_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Setup helper that registers and logs in a streamer.

      setup :register_and_log_in_streamer

  """
  def register_and_log_in_streamer(%{conn: conn}) do
    user = Glimesh.AccountsFixtures.streamer_fixture()
    channel = Glimesh.Streams.get_channel_for_user(user)
    %{conn: log_in_user(conn, user), user: user, channel: channel}
  end

  @doc """
  Setup helper that registers and logs in admin user.

      setup :register_and_log_in_admin_user

  """
  def register_and_log_in_admin_user(%{conn: conn}) do
    user = Glimesh.AccountsFixtures.admin_fixture()
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Setup helper that registers and logs in admin user.

      setup :register_and_log_in_admin_user

  """
  def register_and_log_in_gct_user(%{conn: conn}) do
    user = Glimesh.AccountsFixtures.gct_fixture(%{tfa_token: "Fake 2fa token", gct_level: 5})
    %{conn: log_in_user(conn, user), user: user}
  end

  def register_and_log_in_gct_user_without_tfa(%{conn: conn}) do
    user = Glimesh.AccountsFixtures.gct_fixture(%{tfa_token: nil, gct_level: 5})
    %{conn: log_in_user(conn, user), user: user}
  end

  @doc """
  Logs the given `user` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_user(conn, user) do
    token = Glimesh.Accounts.generate_user_session_token(user)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:user_token, token)
  end

  def register_admin_and_set_user_token(%{conn: conn}) do
    user = Glimesh.AccountsFixtures.admin_fixture()

    create_token_and_return_context(conn, user)
  end

  def register_and_set_user_token(%{conn: conn}) do
    user = Glimesh.AccountsFixtures.user_fixture()

    create_token_and_return_context(conn, user)
  end

  defp create_token_and_return_context(conn, user) do
    {:ok, %{token: token}} =
      ExOauth2Provider.AccessTokens.create_token(user, %{}, otp_app: :glimesh)

    %{
      conn: conn |> Plug.Conn.put_req_header("authorization", "Bearer #{token}"),
      user: user,
      token: token
    }
  end
end
