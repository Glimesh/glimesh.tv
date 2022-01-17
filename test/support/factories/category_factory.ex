defmodule Glimesh.CategoryFactory do
  @moduledoc """
  Category Factory
  """

  use ExMachina.Ecto, repo: Glimesh.Repo

  defmacro __using__(_) do
    quote do
      def category_factory do
        %Glimesh.Streams.Category{
          name: Faker.Pizza.cheese(),
          slug: Faker.Internet.slug()
        }
      end
    end
  end
end
