standard_categories = %{
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

for {cat, subs} <- standard_categories do
  category =
    Glimesh.Repo.insert!(
      %Glimesh.Streams.Category{
        name: cat,
        tag_name: cat,
        slug: Slug.slugify(cat),
        parent_id: nil
      },
      on_conflict: :nothing
    )

  for sub <- subs do
    Glimesh.Repo.insert!(
      %Glimesh.Streams.Category{
        name: sub,
        tag_name: "#{cat} > #{sub}",
        slug: Slug.slugify(sub),
        parent_id: category.id
      },
      on_conflict: :nothing
    )
  end
end
