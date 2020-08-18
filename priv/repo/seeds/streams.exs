# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Glimesh.Repo.insert!(%Glimesh.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

num_streams = 100

possible_categories = Enum.map(Glimesh.Streams.list_categories(), fn x -> x.id end)

for n <- 1..num_streams do
  category = Enum.random(possible_categories)

  {:ok, user} =
    Glimesh.Accounts.register_user(%{
      username: Faker.Internet.user_name(),
      email: Faker.Internet.email(),
      password: "TestUserPassword!"
    })

  metadata = Glimesh.Streams.get_metadata_for_streamer(user)

  Glimesh.Streams.update_metadata(metadata, %{
    "stream_title" => Faker.Lorem.Shakespeare.hamlet(),
    "category_id" => category
  })
end
