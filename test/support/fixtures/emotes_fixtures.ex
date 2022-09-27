defmodule Glimesh.EmotesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glimesh.Accounts` context.
  """
  alias Glimesh.Emotes.Emote

  import Glimesh.AccountsFixtures

  def static_global_emote_fixture do
    {:ok, %Emote{} = emote} =
      Glimesh.Emotes.create_global_emote(admin_fixture(), %{
        emote: "glimchef",
        animated: false,
        static_file: "test/assets/glimchef.svg",
        approved_at: NaiveDateTime.utc_now(),
      })

    emote
  end

  def animated_global_emote_fixture do
    {:ok, %Emote{} = emote} =
      Glimesh.Emotes.create_global_emote(admin_fixture(), %{
        emote: "glimdance",
        animated: true,
        animated_file: "test/assets/glimdance.gif",
        approved_at: NaiveDateTime.utc_now()
      })

    emote
  end
end
