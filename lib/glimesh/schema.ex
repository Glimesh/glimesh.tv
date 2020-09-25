defmodule Glimesh.Schema do
  @moduledoc """
  GraphQL Schema for the API
  """

  use Absinthe.Schema

  alias Glimesh.Repo

  import_types(Absinthe.Type.Custom)

  import_types(Glimesh.Schema.AccountTypes)
  import_types(Glimesh.Schema.ChannelTypes)

  input_object :stream_metadata_input do
    field :ingest_server, :string
    field :ingest_viewers, :integer

    field :source_bitrate, :integer
    field :source_ping, :integer

    field :recv_packets, :integer
    field :lost_packets, :integer
    field :nack_packets, :integer

    field :vendor_name, :string
    field :vendor_version, :string

    field :video_codec, :string
    field :video_height, :integer
    field :video_width, :integer
    field :audio_codec, :string
  end

  query do
    import_fields(:accounts_queries)
    import_fields(:streams_queries)
  end

  mutation do
    import_fields(:streams_mutations)
  end

  subscription do
    import_fields(:streams_subscriptions)
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Repo, Dataloader.Ecto.new(Repo))

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end
