{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.start()
Faker.start()
# This was causing issues with shared runtime for multiple users of the ecto sandbox
# Ecto.Adapters.SQL.Sandbox.mode(Glimesh.Repo, :manual)
