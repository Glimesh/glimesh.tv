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

  {:ok, channel} =
    Glimesh.Streams.create_channel(user, %{
      "title" => Faker.Lorem.Shakespeare.hamlet(),
      "category_id" => category
    })
end
