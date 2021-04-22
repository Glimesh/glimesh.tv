defmodule GlimeshWeb.ApiNext.AccountTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  alias Glimesh.AccountFollows

  @myself_query """
  query getMyself {
    myself {
      username
    }
  }
  """

  @users_query """
  query getUsers {
    users(first: 200) {
      count
      edges{
        node{
          username
        }
      }
    }
  }
  """

  @user_query_string """
  query getUser($username: String!) {
    user(username: $username) {
      username
    }
  }
  """

  @user_query_number """
  query getUser($id: Number!) {
    user(id: $id) {
      username
    }
  }
  """

  @follower_query_streamname_username_single """
  query getUser($username: String!) {
    followers(userUsername: $username, streamerUsername: $username, first: 200) {
      edges{
        node{
          user{
            username
          }
        }
      }
    }
  }
  """

  @follower_query_streamname_list """
  query getUser($username: String!) {
    followers(streamerUsername: $username, first: 200) {
      edges{
        node{
          user{
            username
          }
        }
      }
    }
  }
  """

  @follower_query_username_list """
  query getUser($username: String!) {
    followers(userUsername: $username, first: 200) {
      edges{
        node{
          user{
            username
          }
        }
      }
    }
  }
  """

  @follower_query_streamid_userid_single """
  query getUser($user_id: Number!) {
    followers(userId: $user_id, streamerId: $user_id, first: 200) {
      edges{
        node{
          user{
            username
          }
        }
      }
    }
  }
  """

  @follower_query_streamid_list """
  query getUser($user_id: Number!) {
    followers(streamerId: $user_id, first: 200) {
      edges{
        node{
          user{
            username
          }
        }
      }
    }
  }
  """

  @follower_query_userid_list """
  query getUser($user_id: Number!) {
    followers(userId: $user_id, first: 200) {
      edges{
        node{
          user{
            username
          }
        }
      }
    }
  }
  """

  @follower_query_list """
  query getUser {
    followers(first: 200) {
      count
      edges{
        node{
          user{
            username
          }
        }
      }
    }
  }
  """

  describe "accounts apinew" do
    setup :register_and_set_user_token

    test "returns myself", %{conn: conn, user: user} do
      conn =
        post(conn, "/apinext", %{
          "query" => @myself_query
        })

      assert json_response(conn, 200) == %{
               "data" => %{"myself" => %{"username" => user.username}}
             }
    end

    test "returns all users", %{conn: conn, user: user} do
      conn =
        post(conn, "/apinext", %{
          "query" => @users_query
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "users" => %{
                   "count" => 1,
                   "edges" => [%{"node" => %{"username" => user.username}}]
                 }
               }
             }
    end

    test "returns a user from username", %{conn: conn, user: user} do
      conn =
        post(conn, "/apinext", %{
          "query" => @user_query_string,
          "variables" => %{username: user.username}
        })

      assert json_response(conn, 200) == %{
               "data" => %{"user" => %{"username" => user.username}}
             }
    end

    test "returns a user from id", %{conn: conn, user: user} do
      conn =
        post(conn, "/apinext", %{
          "query" => @user_query_number,
          "variables" => %{id: user.id}
        })

      assert json_response(conn, 200) == %{
               "data" => %{"user" => %{"username" => user.username}}
             }
    end

    test "returns all followers", %{conn: conn, user: _} do
      streamer = streamer_fixture()
      AccountFollows.follow(streamer, streamer)

      conn =
        post(conn, "/apinext", %{
          "query" => @follower_query_list
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "followers" => %{
                   "count" => 1,
                   "edges" => [%{"node" => %{"user" => %{"username" => streamer.username}}}]
                 }
               }
             }
    end

    test "returns a follower from username and streamer username", %{conn: conn, user: _} do
      streamer = streamer_fixture()
      AccountFollows.follow(streamer, streamer)

      conn =
        post(conn, "/apinext", %{
          "query" => @follower_query_streamname_username_single,
          "variables" => %{username: streamer.username}
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "followers" => %{
                   "edges" => [%{"node" => %{"user" => %{"username" => streamer.username}}}]
                 }
               }
             }
    end

    test "returns all followers from username", %{conn: conn, user: _} do
      streamer = streamer_fixture()
      AccountFollows.follow(streamer, streamer)

      conn =
        post(conn, "/apinext", %{
          "query" => @follower_query_username_list,
          "variables" => %{username: streamer.username}
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "followers" => %{
                   "edges" => [%{"node" => %{"user" => %{"username" => streamer.username}}}]
                 }
               }
             }
    end

    test "returns all followers from streamer username", %{conn: conn, user: _} do
      streamer = streamer_fixture()
      AccountFollows.follow(streamer, streamer)

      conn =
        post(conn, "/apinext", %{
          "query" => @follower_query_streamname_list,
          "variables" => %{username: streamer.username}
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "followers" => %{
                   "edges" => [%{"node" => %{"user" => %{"username" => streamer.username}}}]
                 }
               }
             }
    end

    test "returns a follower from user id and streamer id", %{conn: conn, user: _} do
      streamer = streamer_fixture()
      AccountFollows.follow(streamer, streamer)

      conn =
        post(conn, "/apinext", %{
          "query" => @follower_query_streamid_userid_single,
          "variables" => %{user_id: streamer.id}
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "followers" => %{
                   "edges" => [%{"node" => %{"user" => %{"username" => streamer.username}}}]
                 }
               }
             }
    end

    test "returns all followers from user id", %{conn: conn, user: _} do
      streamer = streamer_fixture()
      AccountFollows.follow(streamer, streamer)

      conn =
        post(conn, "/apinext", %{
          "query" => @follower_query_userid_list,
          "variables" => %{user_id: streamer.id}
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "followers" => %{
                   "edges" => [%{"node" => %{"user" => %{"username" => streamer.username}}}]
                 }
               }
             }
    end

    test "returns all followers from streamer id", %{conn: conn, user: _} do
      streamer = streamer_fixture()
      AccountFollows.follow(streamer, streamer)

      conn =
        post(conn, "/apinext", %{
          "query" => @follower_query_streamid_list,
          "variables" => %{user_id: streamer.id}
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "followers" => %{
                   "edges" => [%{"node" => %{"user" => %{"username" => streamer.username}}}]
                 }
               }
             }
    end
  end
end
