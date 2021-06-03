defmodule Glimesh.Streams.Stream do
  @moduledoc false
  use Ecto.Schema
  use Waffle.Ecto.Schema
  import Ecto.Changeset

  schema "streams" do
    belongs_to :channel, Glimesh.Streams.Channel

    field :title, :string
    belongs_to :category, Glimesh.Streams.Category
    belongs_to :subcategory, Glimesh.Streams.Subcategory

    field :started_at, :naive_datetime
    field :ended_at, :naive_datetime

    field :count_viewers, :integer
    field :count_chatters, :integer

    field :peak_viewers, :integer
    field :peak_chatters, :integer
    field :avg_viewers, :integer
    field :avg_chatters, :integer
    field :new_subscribers, :integer
    field :resub_subscribers, :integer

    field :global_tags, {:array, :integer}
    field :category_tags, {:array, :integer}
    field :viewer_counts, {:array, :integer}, default: []

    field :thumbnail, Glimesh.StreamThumbnail.Type

    has_many :metadata, Glimesh.Streams.StreamMetadata

    timestamps()
  end

  def changeset(stream, attrs \\ %{}) do
    stream
    |> cast(attrs, [
      :title,
      :category_id,
      :subcategory_id,
      :started_at,
      :ended_at,
      :count_viewers,
      :count_chatters,
      :peak_viewers,
      :peak_chatters,
      :avg_viewers,
      :avg_chatters,
      :new_subscribers,
      :resub_subscribers,
      :global_tags,
      :category_tags,
      :viewer_counts
    ])
    |> cast_attachments(attrs, [:thumbnail])
  end

  def stop_changeset(stream, ended_at \\ NaiveDateTime.truncate(NaiveDateTime.utc_now(), :second)) do
    avg_viewers = trunc(Enum.sum(stream.viewer_counts) / length(stream.viewer_counts))

    stream
    |> change()
    |> put_change(:avg_viewers, avg_viewers)
    |> force_change(:ended_at, ended_at)
  end
end
