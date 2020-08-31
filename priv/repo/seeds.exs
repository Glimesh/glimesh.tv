# In this file we load all seeds from the seeds subdirectory
for seed <- "seeds/*.exs" |> Path.expand(__DIR__) |> Path.wildcard() do
  Code.require_file(seed)
end