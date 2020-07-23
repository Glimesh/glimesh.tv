defmodule Glimesh.Presence do
  use Phoenix.Presence,
    otp_app: :glimesh,
    pubsub_server: Glimesh.PubSub

  alias Glimesh.Presence

  def track_presence(pid, topic, key, payload) do
    Presence.track(pid, topic, key, payload)
  end

  def update_presence(pid, topic, key, payload) do
    Presence.update(pid, topic, key, payload)
  end

  def list_presences(topic) do
    Presence.list(topic)
      |> Enum.map(fn {_user_id, data} -> data[:metas]
      |> List.first()
    end)
  end
end
