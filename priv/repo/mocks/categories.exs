
tags = %{
  "Art" => [
    "Digital",
    "Physical"
  ],
  "Music" => [
    "24/7 Music Stream",
    "Live Band",
    "DJ"
  ],
  "Tech" => [
    "3D Printing",
    "Live Stats",
    "Programming",
    "Game Development",
    "Web Development"
  ],
  "IRL" => [
    "Animals",
    "Exploration",
    "Talk Show",
    "News",
    "Cooking",
    "Studying"
  ],
  "Education" => [
    "Anthropology",
    "Business Administration",
    "Chemistry",
    "Church",
    "Economics",
    "Engineering",
    "Oceanography",
    "Political Science",
    "Psychology",
    "Statistics"
  ],
  "Gaming" => [
    "Action",
    "Action-Adventure",
    "Adventure",
    "Board Game",
    "Education",
    "Fighting",
    "Misc",
    "MMO",
    "Music",
    "Party",
    "Platform",
    "Puzzle",
    "Racing",
    "Role-Playing",
    "Sandbox",
    "Shooter",
    "Simulation",
    "Sports",
    "Strategy",
    "Visual Novel"
  ]
}


Enum.each(categories, fn name ->
  category = case Glimesh.ChannelCategories.get_category(Slug.slugify(name)) do
    %Glimesh.Streams.Category{} = category ->
      category
    _ ->
      {:ok, category} = Glimesh.ChannelCategories.create_category(%{name: name})
      category
  end

  Enum.each(Map.get(tags, name), fn tag_name ->
    Glimesh.ChannelCategories.create_tag(%{name: tag_name, category_id: category.id})
  end)

end)
