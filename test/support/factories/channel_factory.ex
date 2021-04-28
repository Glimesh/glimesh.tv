defmodule Glimesh.ChannelFactory do
  @moduledoc """
  Channel Factory
  """

  use ExMachina.Ecto, repo: Glimesh.Repo

  defmacro __using__(_) do
    quote do
      def channel_factory do
        %Glimesh.Streams.Channel{
          title: "Live Stream!",
          user: build(:user),
          status: "offline",
          language: "English"
        }
      end
    end
  end
end
