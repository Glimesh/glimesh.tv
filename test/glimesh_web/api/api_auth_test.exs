defmodule GlimeshWeb.Api.ApiAuthTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures

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
      conn = get(conn, "/api")

      assert json_response(conn, 401) == %{
               "errors" => [%{"message" => "You must be logged in to access the api"}]
             }
    end

    test "gets rejected even with query", %{conn: conn} do
      conn =
        post(conn, "/api", %{
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

      {:ok, app} =
        Glimesh.Apps.create_app(user, %{
          name: "some name",
          description: "some description",
          homepage_url: "https://glimesh.tv/",
          oauth_application: %{
            redirect_uri: "http://localhost:8080/redirect"
          }
        })

      %{
        conn:
          conn
          |> Plug.Conn.put_req_header("authorization", "Client-ID #{app.oauth_application.uid}"),
        client_id: app.oauth_application.uid,
        user: user
      }
    end

    test "gets accepted", %{conn: conn} do
      conn = get(conn, "/api")

      assert json_response(conn, 400) == %{
               "errors" => [%{"message" => "No query document supplied"}]
             }
    end

    test "can get a user", %{conn: conn, user: user} do
      conn =
        post(conn, "/api", %{
          "query" => @user_query,
          "variables" => %{"username" => user.username}
        })

      assert json_response(conn, 200) == %{
               "data" => %{"user" => %{"username" => user.username}}
             }
    end
  end

  describe "authenticated api access with login session" do
    setup :register_and_log_in_admin_user

    test "gets accepted", %{conn: conn} do
      conn = get(conn, "/api")

      assert json_response(conn, 400) == %{
               "errors" => [%{"message" => "No query document supplied"}]
             }
    end

    test "returns myself", %{conn: conn, user: user} do
      conn =
        post(conn, "/api", %{
          "query" => @myself_query
        })

      assert json_response(conn, 200) == %{
               "data" => %{"myself" => %{"username" => user.username}}
             }
    end
  end

  describe "authenticated api access with authorization header" do
    setup :register_and_set_user_token

    test "gets accepted", %{conn: conn} do
      conn = get(conn, "/api")

      assert json_response(conn, 400) == %{
               "errors" => [%{"message" => "No query document supplied"}]
             }
    end

    test "returns myself", %{conn: conn, user: user} do
      conn =
        post(conn, "/api", %{
          "query" => @myself_query
        })

      assert json_response(conn, 200) == %{
               "data" => %{"myself" => %{"username" => user.username}}
             }
    end
  end
end
