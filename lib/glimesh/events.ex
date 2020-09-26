defmodule Glimesh.Events do
  @moduledoc """
  The Glimesh Events module is responsible for triaging events out to whoever needs to know about them.
  """

  @doc """
  Broadcast's some data to the application and api
  """
  def broadcast(topic, event_type, data) do
    broadcast(topic, nil, event_type, data)
  end

  def broadcast(topic, firehose_topic, event_type, data) do
    # 1. Send to Phoenix
    Phoenix.PubSub.broadcast(
      Glimesh.PubSub,
      topic,
      {event_type, data}
    )

    # 2. Send to Absinthe API
    Absinthe.Subscription.publish(
      GlimeshWeb.Endpoint,
      data,
      Keyword.put([], event_type, topic)
    )

    # 3. Send to the Absinthe Firehose API
    if firehose_topic do
      Absinthe.Subscription.publish(
        GlimeshWeb.Endpoint,
        data,
        Keyword.put([], event_type, firehose_topic)
      )
    end
  end
end
