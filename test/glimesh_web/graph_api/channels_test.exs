defmodule GlimeshWeb.GraphApi.ChannelsTest do
  use GlimeshWeb.ConnCase

  alias Glimesh.Streams

  import Glimesh.AccountsFixtures
  import Glimesh.Support.GraphqlHelper

  @channels_query """
  query getChannels {
    channels(first: 200) {
      count
      edges{
        node{
          title
          streamer { username }
        }
      }
    }
  }
  """

  @channels_category_query """
  query getChannels($categorySlug: String!) {
    channels(categorySlug: $categorySlug, status: LIVE, first: 200) {
      count
      edges {
        node {
          title
          streamer { username }
        }
      }
    }
  }
  """

  @channel_query """
  query getChannel($streamerUsername: String!) {
    channel(streamerUsername: $streamerUsername) {
      title
      streamer { username }

      mature_content

      posterUrl
      chatBgUrl

      subcategory {
        name
      }

      tags {
        name
      }
    }
  }
  """

  @channel_all_children_query """
  query getChannel($streamerId: Int!) {
    channel(streamerId: $streamerId) {
      chatMessages(first: 200) {
        count
        edges {
          node {
            message
          }
        }
      }
      bans(first: 200) {
        count
        edges {
          node {
            user {
              username
            }
          }
        }
      }
      moderators(first: 200) {
        count
        edges {
          node {
            user {
              username
            }
          }
        }
      }
      moderationLogs(first: 200) {
        count
        edges {
          node {
            user {
              username
            }
          }
        }
      }

      streams(first: 200) {
        count
        edges {
          node {
            title
          }
        }
      }
    }
  }
  """
  @channel_stream_children_query """
  query getChannel($streamerId: Int!) {
    channel(streamerId: $streamerId) {
      stream {
        title
        metadata(first: 200) {
          count
          edges {
            node {
              id
            }
          }
        }
      }
    }
  }
  """

  @channel_userid_query """
  query getChannel($streamerId: Int!) {
    channel(streamerId: $streamerId) {
      title
      streamer { username }

      mature_content

      subcategory {
        name
      }

      tags {
        name
      }
    }
  }
  """

  describe "channels api basic functionality" do
    setup [:register_and_set_user_token, :create_channel]

    test "returns all channels", %{conn: conn, user: user} do
      assert run_query(conn, @channels_query)["data"] == %{
               "channels" => %{
                 "count" => 1,
                 "edges" => [
                   %{
                     "node" => %{
                       "title" => "Live Stream!",
                       "streamer" => %{"username" => user.username}
                     }
                   }
                 ]
               }
             }
    end

    test "returns all channels in category", %{conn: conn, user: user} do
      assert run_query(conn, @channels_category_query, %{categorySlug: "gaming"})["data"] == %{
               "channels" => %{
                 "count" => 1,
                 "edges" => [
                   %{
                     "node" => %{
                       "title" => "Live Stream!",
                       "streamer" => %{"username" => user.username}
                     }
                   }
                 ]
               }
             }

      assert run_query(conn, @channels_category_query, %{categorySlug: "art"})["data"] == %{
               "channels" => %{
                 "count" => 0,
                 "edges" => []
               }
             }
    end

    test "returns a channel by username", %{conn: conn, user: user} do
      assert run_query(conn, @channel_query, %{streamerUsername: user.username})["data"] == %{
               "channel" => %{
                 "title" => "Live Stream!",
                 "streamer" => %{"username" => user.username},
                 "mature_content" => false,
                 "posterUrl" => "http://localhost:4002/images/stream-not-started.jpg",
                 "chatBgUrl" => "http://localhost:4002/images/bg.png",
                 "subcategory" => %{
                   "name" => "World of Warcraft"
                 },
                 "tags" => [
                   %{
                     "name" => "Chill Stream"
                   }
                 ]
               }
             }
    end

    test "returns a channel by user id", %{conn: conn, user: user} do
      assert run_query(conn, @channel_userid_query, %{streamerId: user.id})["data"] == %{
               "channel" => %{
                 "title" => "Live Stream!",
                 "streamer" => %{"username" => user.username},
                 "mature_content" => false,
                 "subcategory" => %{
                   "name" => "World of Warcraft"
                 },
                 "tags" => [
                   %{
                     "name" => "Chill Stream"
                   }
                 ]
               }
             }
    end

    test "returns a channels node relations", %{conn: conn, user: user} do
      assert run_query(conn, @channel_all_children_query, %{streamerId: user.id})["data"] == %{
               "channel" => %{
                 "bans" => %{"count" => 0, "edges" => []},
                 "chatMessages" => %{"count" => 0, "edges" => []},
                 "moderationLogs" => %{"count" => 0, "edges" => []},
                 "moderators" => %{"count" => 0, "edges" => []},
                 "streams" => %{
                   "count" => 1,
                   "edges" => [%{"node" => %{"title" => "Live Stream!"}}]
                 }
               }
             }
    end

    test "returns a channels stream & node relations", %{conn: conn, user: user} do
      assert run_query(conn, @channel_stream_children_query, %{streamerId: user.id})["data"] == %{
               "channel" => %{
                 "stream" => %{
                   "title" => "Live Stream!",
                   "metadata" => %{"count" => 0, "edges" => []}
                 }
               }
             }
    end
  end

  @categories_query """
  query getCategories {
    categories {
      name
      slug
    }
  }
  """

  @category_query """
  query getCategory($slug: String!) {
    category(slug: $slug) {
      name
      slug

      subcategories(first: 200) {
        count
        edges {
          node {
            name
            backgroundImageUrl
          }
        }
      }

      tags(first: 200) {
        count
        edges {
          node {
            name
          }
        }
      }
    }
  }
  """

  describe "categories api" do
    setup [:register_and_set_user_token, :create_tag, :create_subcategory]

    test "returns all categories", %{conn: conn} do
      resp = run_query(conn, @categories_query)

      assert Enum.member?(
               Enum.map(resp["data"]["categories"], fn x -> x["slug"] end),
               "gaming"
             )
    end

    test "returns a category", %{conn: conn} do
      assert run_query(conn, @category_query, %{slug: "gaming"}) == %{
               "data" => %{
                 "category" => %{
                   "name" => "Gaming",
                   "slug" => "gaming",
                   "subcategories" => %{
                     "count" => 1,
                     "edges" => [
                       %{
                         "node" => %{
                           "name" => "World of Warcraft",
                           "backgroundImageUrl" => nil
                         }
                       }
                     ]
                   },
                   "tags" => %{
                     "count" => 1,
                     "edges" => [%{"node" => %{"name" => "Chill Stream"}}]
                   }
                 }
               }
             }
    end
  end

  def create_channel(%{user: user}) do
    user =
      user
      |> Ecto.Changeset.change(%{
        confirmed_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
        can_stream: true
      })
      |> Glimesh.Repo.update!()

    gaming_id = Glimesh.ChannelCategories.get_category("gaming").id
    {:ok, channel} = Streams.create_channel(user, %{category_id: gaming_id})

    %{tag: tag} = create_tag(%{})
    %{subcategory: subcategory} = create_subcategory(%{})

    {:ok, channel} =
      channel
      |> Glimesh.Repo.preload([:tags, :subcategory])
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:tags, [tag])
      |> Ecto.Changeset.put_assoc(:subcategory, subcategory)
      |> Glimesh.Repo.update()

    {:ok, _} = Glimesh.Streams.start_stream(channel)

    %{channel: channel}
  end

  def create_subcategory(_) do
    %{subcategory: subcategory_fixture()}
  end

  def create_tag(_) do
    %{tag: tag_fixture()}
  end
end
