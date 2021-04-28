defmodule Glimesh.SubcategoryFactory do
  @moduledoc """
  Subcategory Factory
  """

  use ExMachina.Ecto, repo: Glimesh.Repo

  defmacro __using__(_) do
    quote do
      def subcategory_factory do
        %Glimesh.Streams.Subcategory{
          name: Faker.Pizza.cheese(),
          slug: Faker.Internet.slug(),
          category: build(:category),
          user_created: true
        }
      end
    end
  end
end
