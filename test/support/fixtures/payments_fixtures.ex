defmodule Glimesh.PaymentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Glimesh.Payments` context.
  """

  def platform_founder_subscription_fixture(user) do
    Glimesh.Payments.create_subscription(%{
      user: user,
      stripe_subscription_id: "random_id",
      stripe_product_id: Glimesh.Payments.get_platform_sub_founder_product_id(),
      stripe_price_id: Glimesh.Payments.get_platform_sub_founder_price_id(),
      stripe_current_period_end: 1234,
      price: 100,
      fee: 10,
      payout: 90,
      product_name: "some name",
      is_active: true,
      started_at: NaiveDateTime.utc_now(),
      ended_at: NaiveDateTime.utc_now()
    })
  end

  def platform_supporter_subscription_fixture(user) do
    Glimesh.Payments.create_subscription(%{
      user: user,
      stripe_subscription_id: "random_id",
      stripe_product_id: Glimesh.Payments.get_platform_sub_supporter_product_id(),
      stripe_price_id: Glimesh.Payments.get_platform_sub_supporter_price_id(),
      stripe_current_period_end: 1234,
      price: 100,
      fee: 10,
      payout: 90,
      product_name: "some name",
      is_active: true,
      started_at: NaiveDateTime.utc_now(),
      ended_at: NaiveDateTime.utc_now()
    })
  end

  def channel_subscription_fixture(streamer, user) do
    Glimesh.Payments.create_subscription(%{
      user: user,
      streamer: streamer,
      stripe_subscription_id: "random_id",
      stripe_product_id: Glimesh.Payments.get_channel_sub_base_product_id(),
      stripe_price_id: Glimesh.Payments.get_channel_sub_base_price_id(),
      stripe_current_period_end: 1234,
      price: 100,
      fee: 10,
      payout: 90,
      product_name: "some name",
      is_active: true,
      started_at: NaiveDateTime.utc_now(),
      ended_at: NaiveDateTime.utc_now()
    })
  end
end
