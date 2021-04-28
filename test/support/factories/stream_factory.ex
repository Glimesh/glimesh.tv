defmodule Glimesh.StreamFactory do
  @moduledoc """
  Stream Factory
  """

  use ExMachina.Ecto, repo: Glimesh.Repo

  defmacro __using__(_) do
    quote do
      def stream_factory do
        %Glimesh.Streams.Stream{
          title: Faker.Pizza.cheese(),
          started_at: DateTime.utc_now() |> DateTime.add(-5 * 60, :second)
        }
      end
    end
  end
end
