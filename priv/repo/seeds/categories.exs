categories = ["Art", "Music", "Tech", "IRL", "Education", "Gaming"]

Enum.each(categories, fn name ->
  if is_nil(Glimesh.ChannelCategories.get_category(Slug.slugify(name))) do
    Glimesh.ChannelCategories.create_category(%{name: name})
  end
end)
