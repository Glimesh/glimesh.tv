defmodule GlimeshWeb.Api.PrivilegedChannelTest do
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

  @start_stream_query """
  mutation StartStream($channelId: ID!) {
    startStream(channelId: $channelId) {
      channel {
        id
      }
    }
  }
  """

  @end_stream_by_stream_id_query """
  mutation EndStream($streamId: ID!) {
    endStream(streamId: $streamId) {
      channel {
        id
      }
    }
  }
  """

  @log_stream_metadata_query """
  mutation LogStreamMetadata($streamId: ID!, $metadata: ChannelMetadataInput!) {
    logStreamMetadata(streamId: $streamId, metadata: $metadata) {
      id
    }
  }
  """

  @upload_stream_thumbnail """
  mutation UploadStreamThumbnail($streamId: ID!, $thumbnail: Upload!) {
    uploadStreamThumbnail(streamId: $streamId, thumbnail: $thumbnail) {
      id
      thumbnail
    }
  }
  """

  describe "channel update apis are unavailable unless admin" do
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

    test "cannot access a mutation unless user is admin", %{
      conn: conn,
      channel: channel
    } do
      conn =
        post(conn, "/api", %{
          "query" => @start_stream_query,
          "variables" => %{channelId: "#{channel.id}"}
        })

      assert [
               %{
                 "locations" => _,
                 "message" => "Access denied",
                 "path" => _
               }
             ] = json_response(conn, 200)["errors"]
    end
  end

  describe "privileged channel query api" do
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
  end

  describe "privileged start stop stream functions" do
    setup [:register_admin_and_set_user_token, :create_channel]

    test "can start stream", %{conn: conn, channel: channel} do
      conn =
        post(conn, "/api", %{
          "query" => @start_stream_query,
          "variables" => %{channelId: "#{channel.id}"}
        })

      assert json_response(conn, 200)["data"]["startStream"] == %{
               "channel" => %{"id" => "#{channel.id}"}
             }
    end

    test "can end stream by stream_id", %{conn: conn, channel: channel} do
      {:ok, stream} = Streams.start_stream(channel)

      conn =
        post(conn, "/api", %{
          "query" => @end_stream_by_stream_id_query,
          "variables" => %{streamId: "#{stream.id}"}
        })

      assert json_response(conn, 200)["data"]["endStream"] == %{
               "channel" => %{"id" => "#{channel.id}"}
             }
    end

    test "can't start stream for a user that can't stream", %{conn: conn, channel: channel} do
      channel.user
      |> Ecto.Changeset.change(%{
        confirmed_at: nil,
        can_stream: false
      })
      |> Glimesh.Repo.update!()

      conn =
        post(conn, "/api", %{
          "query" => @start_stream_query,
          "variables" => %{channelId: "#{channel.id}"}
        })

      assert [
               %{
                 "locations" => _,
                 "message" => "User is unauthorized to start a stream.",
                 "path" => _
               }
             ] = json_response(conn, 200)["errors"]
    end

    test "can log stream metadata", %{conn: conn, channel: channel} do
      {:ok, stream} = Streams.start_stream(channel)

      conn =
        post(conn, "/api", %{
          "query" => @log_stream_metadata_query,
          "variables" => %{
            streamId: "#{stream.id}",
            metadata: %{
              audioCodec: "mp3",
              ingestServer: "test",
              ingestViewers: 32,
              streamTimeSeconds: 1024,
              lostPackets: 0,
              nackPackets: 0,
              recvPackets: 100,
              sourceBitrate: 5000,
              sourcePing: 100,
              vendorName: "OBS",
              vendorVersion: "1.0.0",
              videoCodec: "mp4",
              videoHeight: 1024,
              videoWidth: 768
            }
          }
        })

      assert json_response(conn, 200)["data"]["logStreamMetadata"] == %{"id" => "#{stream.id}"}
    end

    test "can upload stream thumbnails", %{conn: conn, channel: channel} do
      {:ok, stream} = Streams.start_stream(channel)

      stream_thumbnail = %Plug.Upload{
        content_type: "image/png",
        path: "test/assets/bbb-splash.png",
        filename: "bbb-splash.png"
      }

      conn =
        post(conn, "/api", %{
          "query" => @upload_stream_thumbnail,
          "variables" => %{
            streamId: "#{stream.id}",
            thumbnail: "thumbnail"
          },
          thumbnail: stream_thumbnail
        })

      resp = json_response(conn, 200)["data"]["uploadStreamThumbnail"]

      assert resp["id"] == "#{stream.id}"
      assert resp["thumbnail"] =~ "#{stream.id}.jpg"
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

    {:ok, channel} = Streams.create_channel(user)
    %{channel: channel}
  end
end
