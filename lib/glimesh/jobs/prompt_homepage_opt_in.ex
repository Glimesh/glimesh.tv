defmodule Glimesh.Jobs.PromptHomepageOptIn do
  @moduledoc false
  use Oban.Worker

  require Logger

  alias Glimesh.ChannelLookups

  @impl Oban.Worker
  def perform(_) do
    Logger.info("Starting Homepage Opt-in Prompt runner")
    start = NaiveDateTime.utc_now()

    {num_ignore_rows, _} = ChannelLookups.update_channels_opted_in_for_homepage()

    Logger.info(
      "Homepage Opt-in Prompt runner - Changed #{num_ignore_rows} of entries to ignore."
    )

    {num_prompt_rows, _} = ChannelLookups.update_prompt_channel_opt_in_for_homepage()

    Logger.info(
      "Homepage Opt-in Prompt runner - Changed #{num_prompt_rows} of entries to prompt."
    )

    complete = NaiveDateTime.utc_now()
    time = NaiveDateTime.diff(complete, start, :millisecond)
    Logger.info("Homepage Opt-in Prompt runner finished in #{time} ms")

    :ok
  rescue
    e ->
      {:error, e}
  end
end
