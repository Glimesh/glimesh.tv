defmodule Glimesh.Streams.Title do
  alias Glimesh.Repo
  alias Glimesh.Streams.Channel
  alias Glimesh.Events

  def change_title(channel, title) do
    title_change =
      channel
      |> Channel.changeset(%{title: title})
      |> Repo.update()

    case title_change do
      {:ok, changeset} ->
        Events.broadcast(
          "streams:channel:#{channel.id}",
          "streams:channel",
          :channel,
          changeset
        )
        {:ok, changeset}

      {:error, error} ->
        {:error, error}
    end
  end
end
