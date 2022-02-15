channels = Glimesh.Repo.all(Glimesh.Streams.Channel)

Enum.map(channels, fn channel ->
  Glimesh.Streams.start_stream(channel)
end)
