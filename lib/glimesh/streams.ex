defmodule Glimesh.Streams do
  @moduledoc """
  The Streams context. Contains Channels, Streams
  """

  import Ecto.Query, warn: false
  alias Glimesh.Accounts.User
  alias Glimesh.ChannelCategories
  alias Glimesh.ChannelLookups
  alias Glimesh.Repo
  alias Glimesh.Streams.{Channel, StreamMetadata}

  defdelegate authorize(action, user, params), to: Glimesh.Streams.Policy

  ## Broadcasting Functions

  def get_subscribe_topic(:channel), do: "streams:channel"
  def get_subscribe_topic(:chat), do: "streams:chat"
  def get_subscribe_topic(:chatters), do: "streams:chatters"
  def get_subscribe_topic(:viewers), do: "streams:viewers"
  def get_subscribe_topic(:channel, channel_id), do: "streams:channel:#{channel_id}"
  def get_subscribe_topic(:chat, channel_id), do: "streams:chat:#{channel_id}"
  def get_subscribe_topic(:chatters, channel_id), do: "streams:chatters:#{channel_id}"
  def get_subscribe_topic(:viewers, channel_id), do: "streams:viewers:#{channel_id}"

  def subscribe_to(topic_atom, channel_id),
    do: sub_and_return(get_subscribe_topic(topic_atom, channel_id))

  defp sub_and_return(topic), do: {Phoenix.PubSub.subscribe(Glimesh.PubSub, topic), topic}

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, %Channel{} = channel}, :channel = event) do
    Glimesh.Events.broadcast(
      get_subscribe_topic(:channel, channel.id),
      get_subscribe_topic(:channel),
      event,
      channel
    )

    {:ok, channel}
  end

  # User API Calls

  def create_channel(
        %User{} = user,
        attrs \\ %{category_id: Enum.at(ChannelCategories.list_categories(), 0).id}
      ) do
    with :ok <- Bodyguard.permit(__MODULE__, :create_channel, user) do
      case ChannelLookups.get_channel_for_user(user, true) do
        %Channel{} = channel ->
          # User has an existing deactivated channel
          reactivate_channel(user, channel)

        nil ->
          %Channel{
            user: user
          }
          |> Channel.create_changeset(attrs)
          |> Repo.insert()
      end
    end
  end

  def update_channel(%User{} = user, %Channel{} = channel, attrs) do
    with :ok <- Bodyguard.permit(__MODULE__, :update_channel, user, channel) do
      new_channel =
        channel
        |> Channel.changeset(attrs)
        |> Repo.update()

      case new_channel do
        {:error, _changeset} ->
          new_channel

        {:ok, changeset} ->
          broadcast_message = Repo.preload(changeset, :category, force: true)
          broadcast({:ok, broadcast_message}, :channel)
      end
    end
  end

  def rotate_stream_key(%User{} = user, %Channel{} = channel) do
    with :ok <- Bodyguard.permit(__MODULE__, :update_channel, user, channel) do
      channel
      |> change_channel()
      |> Channel.hmac_key_changeset()
      |> Repo.update()
    end
  end

  def reactivate_channel(%User{} = user, %Channel{} = channel) do
    with :ok <- Bodyguard.permit(__MODULE__, :delete_channel, user, channel) do
      attrs = %{inaccessible: false}

      channel
      |> Channel.changeset(attrs)
      |> Repo.update()
    end
  end

  def delete_channel(%User{} = user, %Channel{} = channel) do
    with :ok <- Bodyguard.permit(__MODULE__, :delete_channel, user, channel) do
      attrs = %{inaccessible: true}

      channel
      |> Channel.changeset(attrs)
      |> Repo.update()
    end
  end

  # Streams
  def get_stream(id) do
    Repo.get_by(Glimesh.Streams.Stream, id: id)
  end

  def get_stream!(id) do
    Repo.get_by!(Glimesh.Streams.Stream, id: id)
  end

  @doc """
  Starts a stream for a specific channel
  Only called very intentionally by Janus after stream authentication
  Also sends notifications
  """
  def start_stream(%Channel{} = channel) do
    # Even though a service is starting the stream, we check the permissions against the user.
    user = Glimesh.Accounts.get_user!(channel.user_id)

    with :ok <- Bodyguard.permit(__MODULE__, :start_stream, user) do
      # 0. End all current streams
      stop_active_streams(channel)

      tags = Glimesh.ChannelCategories.list_tags_for_channel(channel)

      # 1. Create Stream
      {:ok, stream} =
        create_stream(channel, %{
          title: channel.title,
          category_id: channel.category_id,
          category_tags: Enum.map(tags, & &1.id),
          started_at: DateTime.utc_now() |> DateTime.to_naive()
        })

      # 2. Change Channel to use Stream
      # 3. Change Channel to Live
      {:ok, channel} =
        channel
        |> Channel.start_changeset(%{
          stream_id: stream.id
        })
        |> Repo.update()

      Glimesh.ChannelCategories.increment_tags_usage(tags)

      # 4. Send Notifications
      users = ChannelLookups.list_live_subscribed_followers(channel)

      Glimesh.Streams.ChannelNotifier.deliver_live_channel_notifications(
        users,
        Repo.preload(channel, [:user, :stream, :tags])
      )

      # 5. Broadcast to anyone who's listening
      broadcast_message = Repo.preload(channel, :category, force: true)
      broadcast({:ok, broadcast_message}, :channel)

      {:ok, stream}
    end
  end

  @doc """
  Ends a stream for a specific channel
  Called either intentionally by Janus when the stream ends, or manually by the platform on a timer
  Archives the stream
  """
  def end_stream(%Channel{} = channel) do
    channel = Repo.preload(channel, [:stream])

    {:ok, stream} =
      update_stream(channel.stream, %{
        ended_at: DateTime.utc_now() |> DateTime.to_naive()
      })

    channel
    |> Channel.stop_changeset(%{})
    |> Repo.update()

    {:ok, stream}
  end

  def end_stream(%Glimesh.Streams.Stream{} = stream) do
    {:ok, stream} =
      update_stream(stream, %{
        ended_at: DateTime.utc_now() |> DateTime.to_naive()
      })

    ChannelLookups.get_channel!(stream.channel_id)
    |> Channel.stop_changeset(%{})
    |> Repo.update()

    {:ok, stream}
  end

  def stop_active_streams(%Channel{} = channel) do
    from(
      s in Glimesh.Streams.Stream,
      where: s.channel_id == ^channel.id and is_nil(s.ended_at)
    )
    |> Glimesh.Repo.update_all(set: [ended_at: DateTime.utc_now() |> DateTime.to_naive()])
  end

  def create_stream(%Channel{} = channel, attrs \\ %{}) do
    %Glimesh.Streams.Stream{
      channel: channel
    }
    |> Glimesh.Streams.Stream.changeset(attrs)
    |> Repo.insert()
  end

  def update_stream(%Glimesh.Streams.Stream{} = stream, attrs) do
    stream
    |> Glimesh.Streams.Stream.changeset(attrs)
    |> Repo.update()
  end

  def get_last_stream_metadata(%Glimesh.Streams.Stream{} = stream) do
    Repo.one(
      from(sm in StreamMetadata,
        where: sm.stream_id == ^stream.id,
        limit: 1,
        order_by: [desc: sm.inserted_at]
      )
    )
  end

  def log_stream_metadata(%Glimesh.Streams.Stream{} = stream, attrs \\ %{}) do
    %StreamMetadata{
      stream: stream
    }
    |> StreamMetadata.changeset(attrs)
    |> Repo.insert()

    {:ok, stream |> Repo.preload([:metadata])}
  end

  def prompt_mature_content(%Channel{mature_content: true}, %User{} = user) do
    user_pref = Glimesh.Accounts.get_user_preference!(user)

    !user_pref.show_mature_content
  end

  def prompt_mature_content(%Channel{mature_content: true}, nil), do: true
  def prompt_mature_content(_, _), do: false

  def get_stream_key(%Channel{id: id, hmac_key: hmac_key}), do: "#{id}-#{hmac_key}"

  # System API Calls

  def change_channel(%Channel{} = channel, attrs \\ %{}) do
    Channel.changeset(channel, attrs)
  end

  def is_live?(%Channel{} = channel) do
    channel.status == "live"
  end

  # Private Calls
end
