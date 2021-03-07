defmodule GlimeshWeb.Api.ChannelTest do
  use GlimeshWeb.ConnCase

  alias Glimesh.Streams

  import Glimesh.AccountsFixtures

  @channels_query """
  query getChannels {
    channels(first: 200) {
      title
      streamer { username }
    }
  }
  """

  @channel_query """
  query getChannel($username: String!) {
    channel(username: $username) {
      title
      streamer { username }

      tags {
        name
      }
    }
  }
  """

  describe "channels api" do
    setup [:register_and_set_user_token, :create_channel]

    test "returns all channels", %{conn: conn, user: user} do
      conn =
        post(conn, "/api", %{
          "query" => @channels_query
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "channels" => [
                   %{
                     "title" => "Live Stream!",
                     "streamer" => %{"username" => user.username}
                   }
                 ]
               }
             }
    end

    test "returns a channel", %{conn: conn, user: user} do
      conn =
        post(conn, "/api", %{
          "query" => @channel_query,
          "variables" => %{username: user.username}
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "channel" => %{
                   "title" => "Live Stream!",
                   "streamer" => %{"username" => user.username},
                   "tags" => [
                     %{
                       "name" => "World of Warcraft"
                     }
                   ]
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

      tags {
        name
      }
    }
  }
  """

  describe "categories api" do
    setup [:register_and_set_user_token, :create_tag]

    test "returns all categories", %{conn: conn} do
      conn =
        post(conn, "/api", %{
          "query" => @categories_query
        })

      assert Enum.member?(
               Enum.map(json_response(conn, 200)["data"]["categories"], fn x -> x["slug"] end),
               "gaming"
             )
    end

    test "returns a category", %{conn: conn} do
      conn =
        post(conn, "/api", %{
          "query" => @category_query,
          "variables" => %{slug: "gaming"}
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "category" => %{
                   "name" => "Gaming",
                   "slug" => "gaming",
                   "tags" => [
                     %{
                       "name" => "World of Warcraft"
                     }
                   ]
                 }
               }
             }
    end
  end

  def create_channel(%{user: user}) do
    {:ok, channel} = Streams.create_channel(user)

    %{tag: tag} = create_tag(%{})

    {:ok, _} =
      channel
      |> Glimesh.Repo.preload(:tags)
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.put_assoc(:tags, [tag])
      |> Glimesh.Repo.update()

    %{channel: channel}
  end

  def create_tag(_) do
    %{tag: tag_fixture()}
  end
end
