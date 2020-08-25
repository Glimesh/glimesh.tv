defmodule GlimeshWeb.Api.ApiAuthTest do
  use GlimeshWeb.ConnCase

  @user_query """
  query getUser($username: String!) {
    user(username: $username) {
      username
    }
  }
  """

  @users_query """
  query getUsers {
    users {
      username
    }
  }
  """

  describe "unauthenticated api access" do
    test "gets rejected", %{conn: conn} do
      conn = get(conn, "/api")

      assert json_response(conn, 401) == %{
               "errors" => [%{"message" => "You must be logged in to access the api"}]
             }
    end

    test "gets rejected even with query", %{conn: conn} do
      conn =
        post(conn, "/api", %{
          "query" => @users_query,
          "variables" => %{}
        })

      assert json_response(conn, 401) == %{
               "errors" => [%{"message" => "You must be logged in to access the api"}]
             }
    end
  end

  describe "authenticated api access" do
    setup :register_and_log_in_admin_user

    test "gets accepted", %{conn: conn} do
      conn = get(conn, "/api")

      assert json_response(conn, 400) == %{
               "errors" => [%{"message" => "No query document supplied"}]
             }
    end

    test "returns a user", %{conn: conn, user: user} do
      conn =
        post(conn, "/api", %{
          "query" => @user_query,
          "variables" => %{username: user.username}
        })

      assert json_response(conn, 200) == %{
               "data" => %{"user" => %{"username" => user.username}}
             }
    end
  end
end
