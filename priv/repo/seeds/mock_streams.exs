streams = Glimesh.Repo.all(Glimesh.Streams.Channel)

IO.puts("Make sure to disable Glimesh.Workers.StreamPruner or these streams will be pruned.")

Enum.map(streams, fn channel ->
  Glimesh.Streams.start_stream(channel)
end)
