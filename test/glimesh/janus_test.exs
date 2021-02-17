defmodule Glimesh.JanusTest do
  use Glimesh.DataCase

  alias Glimesh.Janus

  def create_good_edge(hostname, countries, priority \\ 1.0, available \\ true) do
    Janus.create_edge_route(%{
      hostname: hostname,
      url: "https://#{hostname}/janus",
      priority: priority,
      available: available,
      country_codes: countries
    })
  end

  describe "Edge Routing" do
    test "closest_edge_location/1 routes to a close edge location" do
      assert is_nil(Janus.get_closest_edge_location("US"))

      create_good_edge("not-new-york", ["AU"])
      create_good_edge("new-york", ["US"])

      assert Janus.get_closest_edge_location("US").hostname == "new-york"
      assert Janus.get_closest_edge_location("AU").hostname == "not-new-york"
      assert length(Janus.all_edge_routes()) == 2
    end

    test "closest_edge_location/1 routes to a random close edge location" do
      create_good_edge("new-york-2", ["US"])
      create_good_edge("new-york-1", ["US"])

      first_hostname = Janus.get_closest_edge_location("US").hostname

      # Basically just check 20 to see if we get a different match
      assert Enum.reduce_while(1..20, 0, fn _, _ ->
               if first_hostname == Janus.get_closest_edge_location("US").hostname,
                 do: {:cont, false},
                 else: {:halt, true}
             end)
    end

    test "closest_edge_location/1 respects priority and availability" do
      create_good_edge("near-new-york", ["US"], 0.9)
      create_good_edge("new-york", ["US"], 1.0)
      create_good_edge("super-new-york", ["US"], 1.1, false)

      assert Janus.get_closest_edge_location("US").hostname == "new-york"
    end

    test "closest_edge_location/1 falls back to a safe default always" do
      create_good_edge("new-york", ["US"])

      assert Janus.get_closest_edge_location("DE").hostname == "new-york"
    end
  end
end
