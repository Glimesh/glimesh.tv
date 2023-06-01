defmodule Glimesh.Shutdown do
  alias Glimesh.Repo
  alias Glimesh.Payments.Subscription

  import Ecto.Query, warn: false

  require Logger

  def cancel_platform_subs do
    subscription_types = [
      Glimesh.Payments.get_platform_sub_founder_product_id(),
      Glimesh.Payments.get_platform_sub_supporter_product_id()
    ]

    Repo.all(
      from s in Subscription,
        where:
          s.is_active == true and is_nil(s.streamer_id) and
            s.stripe_product_id in ^subscription_types
    )
    |> Repo.preload(:user)
    |> Enum.each(fn sub ->
      case Stripe.Subscription.delete(sub.stripe_subscription_id) do
        {:ok, stripe_sub} ->
          Logger.info("Cancelled #{sub.stripe_subscription_id}")

        _ ->
          Logger.error("Error cancelling #{sub.stripe_subscription_id}")
      end
    end)
  end
end
