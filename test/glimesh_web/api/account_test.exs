defmodule GlimeshWeb.Api.AccountTest do
  use GlimeshWeb.ConnCase

  @myself_query """
  query getMyself {
    myself {
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

  @user_query """
  query getUser($username: String!) {
    user(username: $username) {
      username
    }
  }
  """

  describe "accounts api" do
    setup :register_and_set_user_token

    test "returns myself", %{conn: conn, user: user} do
      conn =
        post(conn, "/api", %{
          "query" => @myself_query
        })

      assert json_response(conn, 200) == %{
               "data" => %{"myself" => %{"username" => user.username}}
             }
    end

    test "returns all users", %{conn: conn, user: user} do
      conn =
        post(conn, "/api", %{
          "query" => @users_query
        })

      assert json_response(conn, 200) == %{
               "data" => %{"users" => [%{"username" => user.username}]}
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
