defmodule GlimeshWeb.Api.ProtectedChannelTest do
  use GlimeshWeb.ConnCase

  alias Glimesh.Streams

  @unauthorized_stream_key_query """
  query getChannel($username: String!) {
    channel(username: $username) {
      streamKey
    }
  }
  """

  @channel_by_id_query """
  query getChannel($id: ID!) {
    channel(id: $id) {
      streamKey
    }
  }
  """

  @channel_by_streamkey_query """
  query getChannel($streamKey: String!) {
    channel(streamKey: $streamKey) {
      title
      streamKey
      streamer { username }
    }
  }
  """

  @create_stream_mutation """
  mutation createStream($channelId: ID!) {
    createStream(channelId: $channelId) {
      id
    }
  }
  """

  @update_stream_mutation """
  mutation updateStream($streamId: ID!) {
    updateStream(id: $streamId) {
      id
    }
  }
  """

  describe "media server api is unavailable unless admin" do
    setup [:register_and_set_user_token, :create_channel]

    test "does not return a stream key value unless user is admin", %{
      conn: conn,
      user: user
    } do
      conn =
        post(conn, "/api", %{
          "query" => @unauthorized_stream_key_query,
          "variables" => %{username: user.username}
        })

      assert [
               %{
                 "locations" => _,
                 "message" => "Unauthorized to access streamKey field.",
                 "path" => _
               }
             ] = json_response(conn, 200)["errors"]
    end

    test "cannot query a stream key value unless user is admin", %{
      conn: conn,
      channel: channel
    } do
      conn =
        post(conn, "/api", %{
          "query" => @channel_by_streamkey_query,
          "variables" => %{streamKey: channel.stream_key}
        })

      assert [
               %{
                 "locations" => _,
                 "message" => "Unauthorized to access streamKey query.",
                 "path" => _
               }
             ] = json_response(conn, 200)["errors"]
    end
  end

  describe "media server api" do
    setup [:register_admin_and_set_user_token, :create_channel]

    test "returns a channel by id", %{conn: conn, channel: channel} do
      conn =
        post(conn, "/api", %{
          "query" => @channel_by_id_query,
          "variables" => %{id: channel.id}
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "channel" => %{
                   "streamKey" => channel.stream_key
                 }
               }
             }
    end

    test "returns a channel by streamkey", %{conn: conn, user: user, channel: channel} do
      conn =
        post(conn, "/api", %{
          "query" => @channel_by_streamkey_query,
          "variables" => %{streamKey: channel.stream_key}
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "channel" => %{
                   "title" => "Live Stream!",
                   "streamKey" => channel.stream_key,
                   "streamer" => %{"username" => user.username}
                 }
               }
             }
    end

    test "creates a stream by channel id", %{conn: conn, channel: channel} do
      conn =
        post(conn, "/api", %{
          "query" => @create_stream_mutation,
          "variables" => %{channelId: channel.id}
        })

      assert %{"createStream" => %{"id" => _}} = json_response(conn, 200)["data"]
    end

    test "updates a stream by channel id", %{conn: conn, channel: channel} do
      {:ok, stream} = Streams.create_stream(channel)

      conn =
        post(conn, "/api", %{
          "query" => @update_stream_mutation,
          "variables" => %{streamId: stream.id}
        })

      assert json_response(conn, 200) == %{
               "data" => %{
                 "updateStream" => %{
                   # ID's come back as strings
                   "id" => "#{stream.id}"
                 }
               }
             }
    end
  end

  def create_channel(%{user: user}) do
    {:ok, channel} = Streams.create_channel(user)
    %{channel: channel}
  end
end
