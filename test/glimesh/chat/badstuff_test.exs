defmodule Glimesh.Chat.BadstuffTest do
  use Glimesh.DataCase

  alias Glimesh.Chat.Parser
  alias Glimesh.Chat.Renderer

  describe "bad text input" do
    @bad_links [
      {"guys join my server owo.uwu.nyaa.:3.awoo", "guys join my server owo.uwu.nyaa.:3.awoo"}
    ]

    ExUnit.Case.register_attribute(__ENV__, :pair)

    for {lhs, rhs} <- @bad_links do
      @pair {lhs, rhs}
      left_hash = :crypto.hash(:sha, lhs) |> Base.encode16()

      test "bad inputs: #{left_hash}", context do
        {l, r} = context.registered.pair

        rendered_output = Parser.parse(l) |> Renderer.render_html()

        assert rendered_output =~ r
      end
    end
  end
end
