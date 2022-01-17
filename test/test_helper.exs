{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.start()
Faker.start()
Ecto.Adapters.SQL.Sandbox.mode(Glimesh.Repo, :manual)
