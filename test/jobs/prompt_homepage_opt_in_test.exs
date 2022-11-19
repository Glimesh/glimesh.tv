defmodule Glimesh.Jobs.PromptHomepageOptInTest do
  use Glimesh.DataCase
  use Bamboo.Test

  import Glimesh.AccountsFixtures

  alias Glimesh.Repo
  alias Glimesh.Streams
  alias Glimesh.Streams.Channel
  alias Glimesh.Jobs.PromptHomepageOptIn

  describe "Prompt user when they are homepage eligible job" do
    test "Streamer does not have enough hours streamed" do
      streamer = streamer_fixture()
      PromptHomepageOptIn.perform([])
      updated_channel = Repo.get(Channel, streamer.channel.id)
      assert updated_channel.prompt_for_homepage == :ineligible
    end

    test "Streamer has enough hours streamed" do
      streamer = streamer_fixture()
      create_ten_hours_of_streams(streamer.channel)

      PromptHomepageOptIn.perform([])
      updated_channel = Repo.get(Channel, streamer.channel.id)
      assert updated_channel.prompt_for_homepage == :prompt
    end

    test "Streamer has enough hours streamed and is already opted-in" do
      streamer = streamer_fixture(%{}, %{show_on_homepage: true})
      create_ten_hours_of_streams(streamer.channel)

      PromptHomepageOptIn.perform([])
      updated_channel = Repo.get(Channel, streamer.channel.id)
      assert updated_channel.prompt_for_homepage == :ignore
    end

    test "Streamer is already set to be prompted" do
      streamer = streamer_fixture(%{}, %{show_on_homepage: false, prompt_for_homepage: :prompt})
      create_ten_hours_of_streams(streamer.channel)

      PromptHomepageOptIn.perform([])
      updated_channel = Repo.get(Channel, streamer.channel.id)
      assert updated_channel.prompt_for_homepage == :prompt
    end

    test "Streamer has acknowledged prompt and should not be prompted again" do
      streamer = streamer_fixture(%{}, %{show_on_homepage: false, prompt_for_homepage: :ignore})
      create_ten_hours_of_streams(streamer.channel)

      PromptHomepageOptIn.perform([])
      updated_channel = Repo.get(Channel, streamer.channel.id)
      assert updated_channel.prompt_for_homepage == :ignore
    end

    test "Streamer has deactivated channel and should be skipped" do
      streamer_one =
        streamer_fixture(%{}, %{
          inaccessible: true,
          show_on_homepage: false,
          prompt_for_homepage: :prompt
        })

      streamer_two =
        streamer_fixture(%{}, %{
          inaccessible: true,
          show_on_homepage: false,
          prompt_for_homepage: :ineligible
        })

      streamer_three =
        streamer_fixture(%{}, %{
          inaccessible: true,
          show_on_homepage: false,
          prompt_for_homepage: :ignore
        })

      create_ten_hours_of_streams(streamer_one.channel)
      create_ten_hours_of_streams(streamer_two.channel)
      create_ten_hours_of_streams(streamer_three.channel)

      PromptHomepageOptIn.perform([])
      updated_channel_one = Repo.get(Channel, streamer_one.channel.id)
      updated_channel_two = Repo.get(Channel, streamer_two.channel.id)
      updated_channel_three = Repo.get(Channel, streamer_three.channel.id)

      assert updated_channel_one.prompt_for_homepage == :prompt
      assert updated_channel_two.prompt_for_homepage == :ineligible
      assert updated_channel_three.prompt_for_homepage == :ignore
    end
  end

  defp create_ten_hours_of_streams(channel) do
    Streams.create_stream(channel, %{
      started_at:
        NaiveDateTime.add(NaiveDateTime.utc_now(), 60 * 60 * -10)
        |> NaiveDateTime.truncate(:second),
      ended_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    })

    Ecto.Changeset.change(channel)
    |> Ecto.Changeset.force_change(:status, "offline")
    |> Repo.update()
  end
end
