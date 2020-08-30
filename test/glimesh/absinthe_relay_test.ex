defmodule Glimesh.AbsintheRelayTest do
  use ExUnit.Case, async: true

  setup do
    relay = start_supervised!(Glimesh.AbsintheRelay)
    %{relay: relay}
  end

  test "spawns buckets", %{registry: registry} do
    Glimesh.AbsintheRelay.create("phoenix_topic", "other_topic")
    assert {:ok, bucket} = Glimesh.AbsintheRelay.lookup(registry, "shopping")

    Glimesh.AbsintheRelay.put(bucket, "milk", 1)
    assert Glimesh.AbsintheRelay.get(bucket, "milk") == 1
  end
end
