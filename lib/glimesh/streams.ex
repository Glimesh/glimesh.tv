defmodule Glimesh.Streams do
  @moduledoc """
  The Streams context. Contains Channels, Streams
  """
  require Logger

  import Ecto.Query, warn: false
  alias Glimesh.Accounts
  alias Glimesh.Accounts.User
  alias Glimesh.ChannelCategories
  alias Glimesh.ChannelLookups
  alias Glimesh.Repo
  alias Glimesh.Streams.{Channel, StreamMetadata}

  defdelegate authorize(action, user, params), to: Glimesh.Streams.Policy

  ## Broadcasting Functions

  def get_subscribe_topic(:channel), do: "streams:channel"
  def get_subscribe_topic(:stream), do: "streams:stream"
  def get_subscribe_topic(:chat), do: "streams:chat"
  def get_subscribe_topic(:chatters), do: "streams:chatters"
  def get_subscribe_topic(:viewers), do: "streams:viewers"
  def get_subscribe_topic(:channel, channel_id), do: "streams:channel:#{channel_id}"
  def get_subscribe_topic(:stream, stream_id), do: "streams:stream:#{stream_id}"
  def get_subscribe_topic(:chat, channel_id), do: "streams:chat:#{channel_id}"
  def get_subscribe_topic(:chatters, channel_id), do: "streams:chatters:#{channel_id}"
  def get_subscribe_topic(:viewers, channel_id), do: "streams:viewers:#{channel_id}"

  def subscribe_to(topic_atom, channel_id),
    do: sub_and_return(get_subscribe_topic(topic_atom, channel_id))

  defp sub_and_return(topic), do: {Phoenix.PubSub.subscribe(Glimesh.PubSub, topic), topic}

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, %Channel{} = channel} = input, :channel = event) do
    Glimesh.Events.broadcast(
      get_subscribe_topic(:channel, channel.id),
      get_subscribe_topic(:channel),
      event,
      channel
    )

    input
  end

  defp broadcast({:ok, %Glimesh.Streams.Stream{} = stream} = input, :stream = event) do
    Glimesh.Events.broadcast(
      get_subscribe_topic(:stream, stream.id),
      get_subscribe_topic(:stream),
      event,
      stream
    )

    input
  end

  # User API Calls

  def create_channel(
        %User{} = user,
        attrs \\ %{category_id: Enum.at(ChannelCategories.list_categories(), 0).id}
      ) do
    with :ok <- Bodyguard.permit(__MODULE__, :create_channel, user) do
      case ChannelLookups.get_any_channel_for_user(user) do
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
  catch
    :exit, _ ->
      {:upload_exit, "Failed to upload channel images"}
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

  # Channel Emote Settings
  def update_emote_settings(%User{} = user, %Channel{} = channel, attrs) do
    with :ok <- Bodyguard.permit(__MODULE__, :update_channel, user, channel) do
      new_channel = Channel.emote_settings_changeset(channel, attrs) |> Repo.update()

      case new_channel do
        {:error, _changeset} ->
          new_channel

        {:ok, changeset} ->
          broadcast_message = Repo.preload(changeset, :category, force: true)
          broadcast({:ok, broadcast_message}, :channel)
      end
    end
  end

  def change_emote_settings(%Channel{} = channel, attrs \\ %{}) do
    Channel.emote_settings_changeset(channel, attrs)
  end

  # Channel Addons
  def update_addons(%User{} = user, %Channel{} = channel, attrs) do
    with :ok <- Bodyguard.permit(__MODULE__, :update_channel, user, channel) do
      new_channel = Channel.addons_changest(channel, attrs) |> Repo.update()

      case new_channel do
        {:error, _changeset} ->
          new_channel

        {:ok, changeset} ->
          broadcast_message = Repo.preload(changeset, :category, force: true)
          broadcast({:ok, broadcast_message}, :channel)
      end
    end
  end

  def change_addons(%Channel{} = channel, attrs \\ %{}) do
    Channel.addons_changest(channel, attrs)
  end

  # Streams
  def get_stream(id) do
    Repo.replica().get_by(Glimesh.Streams.Stream, id: id)
  end

  def get_stream!(id) do
    Repo.replica().get_by!(Glimesh.Streams.Stream, id: id)
  end

  def list_streams(channel) do
    Repo.replica().all(
      from s in Glimesh.Streams.Stream,
        where: s.channel_id == ^channel.id,
        order_by: [desc: s.started_at]
    )
    |> Repo.preload(:category)
  end

  @doc """
  Starts a stream for a specific channel
  Only called very intentionally by Janus after stream authentication
  Also sends notifications
  """
  def start_stream(%Channel{} = channel) do
    # Even though a service is starting the stream, we check the permissions against the user.
    user = Accounts.get_user!(channel.user_id)

    with :ok <- Bodyguard.permit(__MODULE__, :start_stream, user) do
      # 0. End all current streams
      stop_active_streams(channel)

      tags = Glimesh.ChannelCategories.list_tags_for_channel(channel)

      # 1. Create Stream
      {:ok, stream} =
        create_stream(channel, %{
          title: channel.title,
          category_id: channel.category_id,
          subcategory_id: channel.subcategory_id,
          category_tags: Enum.map(tags, & &1.id),
          started_at: DateTime.utc_now() |> DateTime.to_naive()
        })

      # 2. Change Channel to use Stream
      # 3. Change Channel to Live
      {:ok, channel} =
        ChannelLookups.get_channel(channel.id)
        |> Channel.start_changeset(%{
          stream_id: stream.id
        })
        |> Repo.update()

      Glimesh.ChannelCategories.increment_tags_usage(tags)

      # 4. Send Notifications
      Rihanna.schedule(Glimesh.Jobs.StartStreamNotifier, [channel.id], in: :timer.minutes(2))

      # 5. Broadcast to anyone who's listening
      broadcast_message = Repo.preload(channel, [:category, :stream], force: true)
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
    channel =
      ChannelLookups.get_channel(channel.id)
      |> Repo.preload(:stream)

    end_stream(channel.stream)
  end

  def end_stream(%Glimesh.Streams.Stream{} = stream) do
    channel = ChannelLookups.get_channel!(stream.channel_id)

    case Ecto.Multi.new()
         |> Ecto.Multi.update(:stream, Glimesh.Streams.Stream.stop_changeset(stream))
         |> Ecto.Multi.update(:channel, Channel.stop_changeset(channel))
         |> Repo.transaction() do
      {:ok, %{stream: stream, channel: channel}} ->
        broadcast_message = Repo.preload(channel, :category, force: true)
        broadcast({:ok, broadcast_message}, :channel)

        {:ok, stream}

      {:error, _, _, _} ->
        Logger.error("Unable to end stream id=#{stream.id}.")
        {:error, "Failed to end the stream"}
    end
  end

  def stop_active_streams(%Channel{} = channel) do
    from(
      s in Glimesh.Streams.Stream,
      where: s.channel_id == ^channel.id and is_nil(s.ended_at)
    )
    |> Repo.replica().all()
    |> Enum.map(fn stream ->
      stream
      |> Glimesh.Streams.Stream.stop_changeset()
      |> Repo.update()
    end)
  end

  def create_stream(%Channel{} = channel, attrs \\ %{}) do
    %Glimesh.Streams.Stream{
      channel: channel
    }
    |> Glimesh.Streams.Stream.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:stream)
  end

  def update_stream(%Glimesh.Streams.Stream{} = stream, attrs) do
    stream
    |> Glimesh.Streams.Stream.changeset(attrs)
    |> Repo.update()
    |> broadcast(:stream)
  catch
    :exit, _ ->
      {:upload_exit, "Failed to upload thumbnail"}
  end

  def get_last_stream_metadata(%Glimesh.Streams.Stream{} = stream) do
    Repo.one(
      from sm in StreamMetadata,
        where: sm.stream_id == ^stream.id,
        limit: 1,
        order_by: [desc: sm.inserted_at]
    )
  end

  def log_stream_metadata(%Glimesh.Streams.Stream{} = stream, attrs \\ %{}) do
    %StreamMetadata{
      stream: stream
    }
    |> StreamMetadata.changeset(attrs)
    |> Repo.insert()
  end

  # System API Calls

  def list_support_tabs(%User{} = streamer, %Channel{} = channel) do
    can_receive_payments = Accounts.can_receive_payments?(streamer)

    [
      {"subscribe", can_receive_payments && channel.show_subscribe_button},
      {"gift_subscription", can_receive_payments && channel.show_subscribe_button},
      {"donate", can_receive_payments && channel.show_donate_button},
      {"streamloots", channel.show_streamloots_button && not is_nil(channel.streamloots_url)}
    ]
    |> Enum.filter(fn {_, testcase} -> testcase end)
    |> Enum.map(fn {tab, _} -> tab end)
  end

  def prompt_mature_content(%Channel{mature_content: true}, %User{} = user) do
    user_pref = Accounts.get_user_preference!(user)

    !user_pref.show_mature_content
  end

  def prompt_mature_content(%Channel{mature_content: true}, nil), do: true
  def prompt_mature_content(_, _), do: false

  def get_stream_key(%Channel{id: id, hmac_key: hmac_key}), do: "#{id}-#{hmac_key}"

  def get_channel_hours(%Channel{id: id}) do
    hours =
      Repo.one(
        from s in Glimesh.Streams.Stream,
          select:
            fragment(
              "sum(EXTRACT(EPOCH FROM ?) - EXTRACT(EPOCH FROM ?)) / 3600",
              s.ended_at,
              s.started_at
            ),
          where: s.channel_id == ^id,
          group_by: s.channel_id
      )

    trunc_hours(hours)
  end

  defp trunc_hours(%Decimal{} = dec) do
    dec |> Decimal.round(0, :up) |> Decimal.to_integer()
  end

  defp trunc_hours(hours) when is_float(hours) do
    hours |> trunc()
  end

  defp trunc_hours(hours) when is_integer(hours) do
    hours
  end

  defp trunc_hours(_), do: 0

  def change_channel(%Channel{} = channel, attrs \\ %{}) do
    Channel.changeset(channel, attrs)
  end

  def get_channel_language(%Channel{language: locale}) do
    case Application.get_env(:glimesh, :locales) |> List.keyfind(locale, 1) do
      {name, _} -> Atom.to_string(name)
      _ -> ""
    end
  end

  def is_live?(%Channel{} = channel) do
    channel.status == "live"
  end

  # Private Calls
end
