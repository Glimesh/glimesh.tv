defmodule Glimesh.UserFactory do
  @moduledoc """
  User Account Factory
  """

  use ExMachina.Ecto, repo: Glimesh.Repo
  alias Faker.Internet

  defmacro __using__(_) do
    quote do
      def user_factory do
        %Glimesh.Accounts.User{
          username: Internet.user_name(),
          displayname: Internet.user_name(),
          email: Internet.email(),
          hashed_password: "",
          confirmed_at: DateTime.utc_now(),
          user_ip: Internet.ip_v4_address(),
          tax_withholding_percent: 0.24
        }
      end

      def user_with_follower(user) do
        insert(:follower, user: build(:user), streamer: user)
        user
      end

      def user_with_follow(user) do
        insert(:follower, user: user, streamer: build(:user))
        user
      end
    end
  end
end
