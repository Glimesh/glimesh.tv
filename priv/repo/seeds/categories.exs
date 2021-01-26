categories = ["Art", "Music", "Tech", "IRL", "Education", "Gaming"]

Enum.each(categories, fn name ->
  Glimesh.Repo.insert!(
      %Glimesh.Streams.Category{
        name: name,
        slug: Slug.slugify(name)
      },
      on_conflict: :nothing,
      conflict_target: :name
    )
end)
