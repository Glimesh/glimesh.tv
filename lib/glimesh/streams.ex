defmodule Glimesh.Streams do
  @moduledoc """
  The Streamers context.
  """

  import Ecto.Query, warn: false
  alias Glimesh.Accounts.User
  alias Glimesh.Chat
  alias Glimesh.Repo
  alias Glimesh.Streams.Category
  alias Glimesh.Streams.Followers
  alias Glimesh.Streams.Metadata
  alias Glimesh.Streams.UserModerationLog
  alias Glimesh.Streams.UserModerator

  ## Database getters

  @doc """
  Get all streamers.

  ## Examples

      iex> list_streams()
      []

  """
  def list_streams do
    Repo.all(from u in User, where: u.can_stream == true)
  end

  def list_in_category(category) do
    # Repo.all(
    #   from u in User,
    #     join: sm in Metadata,
    #     on: u.id == sm.streamer_id,
    #     join: c in Category,
    #     on: c.id == sm.category_id,
    #     where: c.id == ^category.id or c.parent_id == ^category.id
    # )
    Repo.all(
      from sm in Metadata,
        join: c in Category,
        on: c.id == sm.category_id,
        where: c.id == ^category.id or c.parent_id == ^category.id
    )
    |> Repo.preload([:category, :streamer])
  end

  def get_by_username(username) when is_binary(username) do
    Repo.get_by(User, username: username, can_stream: true)
  end

  def get_by_username!(username) when is_binary(username) do
    Repo.get_by!(User, username: username, can_stream: true)
  end

  def add_moderator(streamer, moderator) do
    %UserModerator{
      streamer: streamer,
      user: moderator
    }
    |> UserModerator.changeset(%{
      :can_short_timeout => true,
      :can_long_timeout => true,
      :can_un_timeout => true,
      :can_ban => true,
      :can_unban => true
    })
    |> Repo.insert()
  end

  def timeout_user(streamer, moderator, user_to_timeout) do
    if Chat.can_moderate?(streamer, moderator) === false do
      raise "User does not have permission to moderate."
    end

    log =
      %UserModerationLog{
        streamer: streamer,
        moderator: moderator,
        user: user_to_timeout
      }
      |> UserModerationLog.changeset(%{action: "timeout"})
      |> Repo.insert()

    :ets.insert(:banned_list, {user_to_timeout.username, true})

    Chat.delete_chat_messages_for_user(streamer, user_to_timeout)

    broadcast_chats({:ok, user_to_timeout}, :user_timedout)

    log
  end

  def ban_user(streamer, moderator, user_to_ban) do
    timeout_user(streamer, moderator, user_to_ban)
  end

  defp broadcast_chats({:error, _reason} = error, _event), do: error

  defp broadcast_chats({:ok, chat_message}, event) do
    Phoenix.PubSub.broadcast(Glimesh.PubSub, "chats", {event, chat_message})
    {:ok, chat_message}
  end

  def list_followed_streams(user) do
    Repo.all(
      from f in Followers,
        where: f.user_id == ^user.id,
        join: streamer in assoc(f, :streamer),
        select: streamer
    )
  end

  def follow(streamer, user, live_notifications \\ false) do
    attrs = %{
      has_live_notifications: live_notifications
    }

    results =
      %Followers{
        streamer: streamer,
        user: user
      }
      |> Followers.changeset(attrs)
      |> Repo.insert()

    Glimesh.Chat.create_chat_message(streamer, user, %{message: "just followed the stream!"})

    results
  end

  def unfollow(streamer, user) do
    Repo.get_by(Followers, streamer_id: streamer.id, user_id: user.id) |> Repo.delete()
  end

  def is_following?(streamer, user) do
    Repo.exists?(
      from f in Followers, where: f.streamer_id == ^streamer.id and f.user_id == ^user.id
    )
  end

  def count_followers(user) do
    Repo.one!(from f in Followers, select: count(f.id), where: f.streamer_id == ^user.id)
  end

  def count_following(user) do
    Repo.one!(from f in Followers, select: count(f.id), where: f.user_id == ^user.id)
  end

  alias Glimesh.Streams.Metadata

  def get_metadata_for_streamer(streamer) do
    metadata =
      case Repo.get_by(Metadata, streamer_id: streamer.id) do
        nil ->
          {:ok, metadata} = create_metadata(streamer)
          metadata

        %Metadata{} = metadata ->
          metadata
      end

    metadata |> Repo.preload([:category])
  end

  @doc """
  Creates some metadata.

  ## Examples

      iex> create_metadata(%{field: value})
      {:ok, %Metadata{}}

      iex> create_metadata(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_metadata(streamer, attrs \\ %{}) do
    %Metadata{
      streamer: streamer
    }
    |> Metadata.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates some metadata.

  ## Examples

      iex> update_metadata(metadata, %{field: new_value})
      {:ok, %Metadata{}}

      iex> update_metadata(metadata, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_metadata(%Metadata{} = metadata, attrs) do
    new_meta =
      metadata
      |> Metadata.changeset(attrs)
      |> Repo.update!()
      |> Repo.preload(:category, force: true)

    broadcast({:ok, new_meta}, :update_metadata)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking metadata changes.

  ## Examples

      iex> change_metadata(category)
      %Ecto.Changeset{data: %Metadata{}}

  """
  def change_metadata(%Metadata{} = metadata, attrs \\ %{}) do
    Metadata.changeset(metadata, attrs)
  end

  def get_metadata_from_streamer(streamer) do
    data = Repo.get_by(Metadata, streamer_id: streamer.id) |> Repo.preload([:category])

    case data do
      nil ->
        create_metadata(streamer)
        get_metadata_from_streamer(streamer)

      _ ->
        data
    end
  end

  @spec subscribe_metadata(any) :: :ok | {:error, {:already_registered, pid}}
  def subscribe_metadata(streamer_id) do
    Phoenix.PubSub.subscribe(Glimesh.PubSub, "streams:#{streamer_id}:metadata")
  end

  defp broadcast({:error, _reason} = error, _event), do: error

  defp broadcast({:ok, data}, :update_metadata = event) do
    Phoenix.PubSub.broadcast(
      Glimesh.PubSub,
      "streams:#{data.streamer_id}:metadata",
      {event, data}
    )

    {:ok, data}
  end

  alias Glimesh.Streams.Category

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Repo.all(Category) |> Repo.preload(:parent)
  end

  def list_categories_for_select do
    # Repo.all(from c in Category, order_by: [asc: :id, asc: :parent_id, asc: :name])
    # |> Enum.map(fn x ->
    #   name = if x.parent_id, do: " - #{x.name}", else: x.name
    #   {name, x.id}
    # end)

    Repo.all(from c in Category, order_by: [asc: :tag_name])
    |> Enum.map(&{&1.tag_name, &1.id})
  end

  def list_parent_categories do
    Repo.all(from c in Category, where: is_nil(c.parent_id))
  end

  @spec list_categories_by_parent(atom | %{id: any}) :: any
  def list_categories_by_parent(category) do
    Repo.all(from c in Category, where: c.parent_id == ^category.id)
  end

  def list_subcategories_and_streams(category) do
    Repo.all(
      from sm in Metadata,
        join: c in Category,
        on: c.id == sm.category_id,
        where: c.id == ^category.id or c.parent_id == ^category.id
    )
    |> Repo.preload([:streamer, :category])
    |> Enum.group_by(fn x -> x.category.name end)
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(slug),
    do: Repo.one(from c in Category, where: c.slug == ^slug and is_nil(c.parent_id))

  def get_category_by_id!(id), do: Repo.get_by!(Category, id: id)

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end
end
