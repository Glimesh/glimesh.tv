defmodule GlimeshWeb.GraphApi.AuthTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  import Glimesh.ApiFixtures

  @myself_query """
  query getMyself {
    myself {
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

  describe "unauthenticated api access" do
    test "gets rejected", %{conn: conn} do
      conn = get(conn, "/api/graph")

      assert json_response(conn, 401) == %{
               "errors" => [%{"message" => "You must be logged in to access the api"}]
             }
    end

    test "gets rejected even with query", %{conn: conn} do
      conn =
        post(conn, "/api/graph", %{
          "query" => @user_query,
          "variables" => %{"username" => "foobar"}
        })

      assert json_response(conn, 401) == %{
               "errors" => [%{"message" => "You must be logged in to access the api"}]
             }
    end
  end

  describe "read-only api access with client id" do
    setup %{conn: conn} do
      user = user_fixture()
      {:ok, app} = app_fixture(user)

      %{
        conn:
          conn
          |> Plug.Conn.put_req_header("authorization", "Client-ID #{app.client_id}"),
        client_id: app.client_id,
        user: user
      }
    end

    test "gets accepted", %{conn: conn} do
      conn = get(conn, "/api/graph")

      assert json_response(conn, 400) == %{
               "errors" => [%{"message" => "No query document supplied"}]
             }
    end

    test "can get a user", %{conn: conn, user: user} do
      conn =
        post(conn, "/api/graph", %{
          "query" => @user_query,
          "variables" => %{"username" => user.username}
        })

      assert json_response(conn, 200) == %{
               "data" => %{"user" => %{"username" => user.username}}
             }
    end
  end

  describe "authenticated does not allow api access" do
    setup :register_and_log_in_admin_user

    test "gets rejected", %{conn: conn} do
      conn = get(conn, "/api/graph")

      assert json_response(conn, 401) == %{
               "errors" => [%{"message" => "You must be logged in to access the api"}]
             }
    end
  end

  describe "authenticated api access with authorization header" do
    setup :register_and_set_user_token

    test "gets accepted", %{conn: conn} do
      conn = get(conn, "/api/graph")

      assert json_response(conn, 400) == %{
               "errors" => [%{"message" => "No query document supplied"}]
             }
    end

    test "returns myself", %{conn: conn, user: user} do
      conn =
        post(conn, "/api/graph", %{
          "query" => @myself_query
        })

      assert json_response(conn, 200) == %{
               "data" => %{"myself" => %{"username" => user.username}}
             }
    end
  end

  describe "weird other auth methods for the api" do
    setup :register_and_set_user_token

    test "authenticated api access with lowercased authorization header gets accepted", %{
      conn: conn,
      user: user,
      token: token
    } do
      conn =
        conn
        |> Plug.Conn.put_req_header(
          "authorization",
          "bearer #{token}"
        )

      conn =
        post(conn, "/api/graph", %{
          "query" => @myself_query
        })

      assert json_response(conn, 200) == %{
               "data" => %{"myself" => %{"username" => user.username}}
             }
    end

    test "bearer token with missing token gets rejected", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header(
          "authorization",
          "Bearer "
        )

      conn = post(conn, "/api/graph", %{"query" => @myself_query})

      assert json_response(conn, 401) == %{
               "errors" => [
                 %{
                   "message" => "Provided access token is invalid.",
                   "header_error" => "invalid_access_token"
                 }
               ]
             }
    end
  end
end
