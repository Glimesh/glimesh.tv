defmodule GlimeshWeb.GraphApi.AccountsTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  import Glimesh.Support.GraphqlHelper

  alias Glimesh.AccountFollows
  alias Glimesh.Streams

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

  @user_query_nodes """
  query getUser($id: Number!) {
    user(id: $id) {
      followingLiveChannels {
        count
        edges {
          node {
            streamer {
              username
            }
          }
        }
      }

      following {
        count
        edges {
          node {
            streamer {
              username
            }
          }
        }
      }

      followers {
        count
        edges {
          node {
            user {
              username
            }
          }
        }
      }
    }
  }
  """

  @follower_query_streamerid_userid_single """
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

  @follower_query_streamerid_list """
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

  @follow_create_mutation """
  mutation FollowCreate($channelId: ID!) {
    follow(channelId: $channelId) {
      user {
        username
      }
      hasLiveNotifications
    }
  }
  """

  @follow_update_mutation """
  mutation FollowUpdate($channelId: ID!, $liveNotifications: Boolean!) {
    follow(channelId: $channelId, liveNotifications: $liveNotifications) {
      user {
        username
      }
      hasLiveNotifications
    }
  }
  """

  @unfollow_mutation """
  mutation FollowRemove($channelId: ID!) {
    unfollow(channelId: $channelId) {
      user {
        username
      }
    }
  }
  """

  describe "accounts api basic functionality" do
    setup :register_and_set_user_token

    test "returns myself", %{conn: conn, user: user} do
      assert run_query(conn, @myself_query)["data"] == %{
               "myself" => %{"username" => user.username}
             }
    end

    test "returns all users", %{conn: conn, user: user} do
      assert run_query(conn, @users_query)["data"] == %{
               "users" => %{
                 "count" => 1,
                 "edges" => [%{"node" => %{"username" => user.username}}]
               }
             }
    end

    test "returns a user from username", %{conn: conn, user: user} do
      assert run_query(conn, @user_query_string, %{username: user.username})["data"] == %{
               "user" => %{"username" => user.username}
             }
    end

    test "returns a user from id", %{conn: conn, user: user} do
      assert run_query(conn, @user_query_number, %{id: user.id})["data"] == %{
               "user" => %{"username" => user.username}
             }
    end

    test "returns all followers in node relation", %{conn: conn, user: user} do
      streamer = streamer_fixture()

      Glimesh.Streams.start_stream(streamer.channel)

      random_user = user_fixture()
      AccountFollows.follow(user, random_user)
      AccountFollows.follow(streamer, user)

      assert run_query(conn, @user_query_nodes, %{id: user.id})["data"] == %{
               "user" => %{
                 "followers" => %{
                   "count" => 1,
                   "edges" => [%{"node" => %{"user" => %{"username" => random_user.username}}}]
                 },
                 "followingLiveChannels" => %{
                   "count" => 1,
                   "edges" => [%{"node" => %{"streamer" => %{"username" => streamer.username}}}]
                 },
                 "following" => %{
                   "count" => 1,
                   "edges" => [%{"node" => %{"streamer" => %{"username" => streamer.username}}}]
                 }
               }
             }
    end

    test "returns all followers", %{conn: conn, user: _} do
      streamer = streamer_fixture()
      AccountFollows.follow(streamer, streamer)

      assert run_query(conn, @follower_query_list)["data"] == %{
               "followers" => %{
                 "count" => 1,
                 "edges" => [%{"node" => %{"user" => %{"username" => streamer.username}}}]
               }
             }
    end

    test "returns a follower from user id and streamer id", %{conn: conn} do
      streamer = streamer_fixture()
      AccountFollows.follow(streamer, streamer)

      resp =
        run_query(conn, @follower_query_streamerid_userid_single, %{user_id: streamer.id})["data"]

      assert resp == %{
               "followers" => %{
                 "edges" => [%{"node" => %{"user" => %{"username" => streamer.username}}}]
               }
             }
    end

    test "returns all followers from user id", %{conn: conn} do
      streamer = streamer_fixture()
      AccountFollows.follow(streamer, streamer)

      resp = run_query(conn, @follower_query_userid_list, %{user_id: streamer.id})["data"]

      assert resp == %{
               "followers" => %{
                 "edges" => [%{"node" => %{"user" => %{"username" => streamer.username}}}]
               }
             }
    end

    test "returns all followers from streamer id", %{conn: conn} do
      streamer = streamer_fixture()
      AccountFollows.follow(streamer, streamer)

      resp = run_query(conn, @follower_query_streamerid_list, %{user_id: streamer.id})["data"]

      assert resp == %{
               "followers" => %{
                 "edges" => [%{"node" => %{"user" => %{"username" => streamer.username}}}]
               }
             }
    end
  end

  @query_user_info """
  query getUser($id: Number!) {
    user(id: $id) {
      username
      email
      avatarUrl
    }
  }
  """

  describe "accounts api resolvers" do
    setup :register_and_set_user_token

    test "avatarUrl return the correct response", %{conn: conn, user: user} do
      resp = run_query(conn, @query_user_info, %{id: user.id})["data"]
      email_hash = :crypto.hash(:md5, user.email) |> Base.encode16(case: :lower)

      assert resp == %{
               "user" => %{
                 "username" => user.username,
                 "email" => user.email,
                 "avatarUrl" => "https://www.gravatar.com/avatar/#{email_hash}?s=200&d=wavatar"
               }
             }

      new_avatar = %Plug.Upload{
        content_type: "image/png",
        path: "test/assets/bbb-splash.png",
        filename: "bbb-splash.png"
      }

      {:ok, user} = Glimesh.Accounts.update_user_profile(user, %{avatar: new_avatar})
      resp = run_query(conn, @query_user_info, %{id: user.id})["data"]

      # Will not return the full path in testing
      assert get_in(resp, ["user", "avatarUrl"]) =~ "/uploads/avatars/user"
    end
  end

  describe "accounts api follow mutations without scope" do
    setup [:create_user, :create_channel]

    setup context do
      create_token_and_return_context(context.conn, context.user, "public")
    end

    test "cannot follow a channel", %{conn: conn, channel: channel} do
      resp =
        run_query(conn, @follow_create_mutation, %{
          channelId: "#{channel.id}"
        })

      assert is_nil(resp["data"]["follow"])

      assert [
               %{
                 "locations" => _,
                 "message" => "unauthorized",
                 "path" => _
               }
             ] = resp["errors"]
    end

    test "cannot update a follow", %{conn: conn, channel: channel} do
      resp =
        run_query(conn, @follow_update_mutation, %{
          channelId: "#{channel.id}",
          liveNotifications: true
        })

      assert is_nil(resp["data"]["follow"])

      assert [
               %{
                 "locations" => _,
                 "message" => "unauthorized",
                 "path" => _
               }
             ] = resp["errors"]
    end

    test "cannot remove a follow", %{conn: conn, channel: channel} do
      resp =
        run_query(conn, @unfollow_mutation, %{
          channelId: "#{channel.id}"
        })

      assert is_nil(resp["data"]["unfollow"])

      assert [
               %{
                 "locations" => _,
                 "message" => "unauthorized",
                 "path" => _
               }
             ] = resp["errors"]
    end
  end

  describe "accounts api follow mutations" do
    setup [:register_and_set_user_token, :create_channel]

    test "can follow a channel", %{conn: conn, user: user, channel: channel} do
      resp =
        run_query(conn, @follow_create_mutation, %{
          channelId: "#{channel.id}"
        })

      assert resp["errors"] == nil

      assert resp["data"]["follow"] == %{
               "user" => %{
                 "username" => user.username
               },
               "hasLiveNotifications" => false
             }
    end

    test "can update a follow", %{conn: conn, user: user} do
      streamer = streamer_fixture()
      {:ok, follower} = AccountFollows.follow(streamer, user)
      assert follower.has_live_notifications == false

      resp =
        run_query(conn, @follow_update_mutation, %{
          channelId: "#{streamer.channel.id}",
          liveNotifications: true
        })

      assert resp["errors"] == nil

      assert resp["data"]["follow"] == %{
               "user" => %{
                 "username" => user.username
               },
               "hasLiveNotifications" => true
             }
    end

    test "updating a follow without setting liveNotifications sets it to false", %{
      conn: conn,
      user: user
    } do
      streamer = streamer_fixture()
      {:ok, follower} = AccountFollows.follow(streamer, user, true)
      assert follower.has_live_notifications == true

      resp =
        run_query(conn, @follow_create_mutation, %{
          channelId: "#{streamer.channel.id}"
        })

      assert resp["errors"] == nil

      assert resp["data"]["follow"] == %{
               "user" => %{
                 "username" => user.username
               },
               "hasLiveNotifications" => false
             }
    end

    test "can remove a follow", %{conn: conn, user: user} do
      streamer = streamer_fixture()
      {:ok, _} = AccountFollows.follow(streamer, user)

      resp =
        run_query(conn, @unfollow_mutation, %{
          channelId: "#{streamer.channel.id}"
        })

      assert resp["errors"] == nil

      assert resp["data"]["unfollow"] == %{
               "user" => %{
                 "username" => user.username
               }
             }
    end

    test "can follow a channel twice", %{conn: conn, user: user} do
      streamer = streamer_fixture()
      {:ok, _} = AccountFollows.follow(streamer, user)

      resp =
        run_query(conn, @follow_create_mutation, %{
          channelId: "#{streamer.channel.id}"
        })

      assert resp["errors"] == nil

      assert resp["data"]["follow"] == %{
               "user" => %{
                 "username" => user.username
               },
               "hasLiveNotifications" => false
             }
    end

    test "cannot remove a follow if channel is not followed", %{conn: conn, channel: channel} do
      resp =
        run_query(conn, @unfollow_mutation, %{
          channelId: "#{channel.id}"
        })

      assert is_nil(resp["data"]["unfollow"])

      assert [
               %{
                 "locations" => _,
                 "message" => "Not following",
                 "path" => _
               }
             ] = resp["errors"]
    end
  end

  describe "accounts api scoped functionality" do
    setup :register_and_set_user_token

    test "you can get your own email but not someone elses", %{conn: conn, user: user} do
      assert get_in(run_query(conn, @query_user_info, %{id: user.id}), ["data", "user", "email"]) ==
               user.email

      another_user = user_fixture()

      assert get_in(run_query(conn, @query_user_info, %{id: another_user.id}), [
               "data",
               "user",
               "email"
             ]) == nil
    end
  end

  def create_user(_) do
    %{user: user_fixture()}
  end

  def create_channel(%{user: user}) do
    {:ok, channel} = Streams.create_channel(user)
    %{channel: channel}
  end
end
