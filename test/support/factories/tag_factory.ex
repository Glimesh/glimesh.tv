defmodule Glimesh.TagFactory do
  @moduledoc """
  Tag Factory
  """

  use ExMachina.Ecto, repo: Glimesh.Repo

  defmacro __using__(_) do
    quote do
      def tag_factory do
        %Glimesh.Streams.Tag{
          name: Faker.Pizza.cheese(),
          slug: Faker.Internet.slug(),
          category: build(:category)
        }
      end
    end
  end
end
