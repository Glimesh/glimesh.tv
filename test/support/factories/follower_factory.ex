defmodule Glimesh.FollowerFactory do
  @moduledoc """
  Follower Factory
  """

  use ExMachina.Ecto, repo: Glimesh.Repo

  defmacro __using__(_) do
    quote do
      def follower_factory do
        %Glimesh.AccountFollows.Follower{
          streamer: build(:user),
          user: build(:user)
        }
      end
    end
  end
end
