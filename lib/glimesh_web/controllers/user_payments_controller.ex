defmodule GlimeshWeb.UserPaymentsController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias Glimesh.Payments

  plug :put_layout, "user-sidebar.html"

  def index(conn, _params) do
    user = conn.assigns.current_user

    params =
      Plug.Conn.Query.encode(%{
        "client_id" => Application.get_env(:stripity_stripe, :connect_client_id),
        "state" => Plug.CSRFProtection.get_csrf_token(),
        "suggested_capabilities" => ["transfers", "card_payments"],
        "stripe_user" => %{
          "email" => user.email,
          "url" => Routes.user_stream_url(conn, :index, user.username)
        }
      })

    stripe_oauth_url = "https://connect.stripe.com/express/oauth/authorize?" <> params

    render(
      conn,
      "index.html",
      is_sub_ready_streamer: !is_nil(user.stripe_user_id),
      stripe_oauth_url: stripe_oauth_url,
      has_platform_subscription: Payments.has_platform_subscription?(user),
      subscriptions: Payments.get_channel_subscriptions(user),
      default_payment_changeset: Accounts.change_stripe_default_payment(user),
      has_payment_method: !is_nil(user.stripe_payment_method)
    )
  end

  def connect(conn, %{"state" => state, "code" => code}) do
    user = conn.assigns.current_user
    #    Plug.CSRFProtection.valid_state_and_csrf_token?(state)
    case Payments.oauth_connect(user, code) do
      {:ok, _} ->
        conn
        |> put_flash(
          :info,
          gettext("Stripe account linked successfully, welcome to the sub club!")
        )
        |> redirect(to: Routes.user_payments_path(conn, :index))

      {:error, err} ->
        conn
        |> put_flash(:error, err)
        |> redirect(to: Routes.user_payments_path(conn, :index))
    end
  end

  def delete_default_payment(conn, %{}) do
    user = conn.assigns.current_user

    case Accounts.set_stripe_default_payment(user, nil) do
      {:ok, _} ->
        conn
        |> put_flash(:info, gettext("Payment method deleted!"))
        |> redirect(to: Routes.user_payments_path(conn, :index))

      {:error, err} ->
        conn
        |> put_flash(:error, err)
        |> redirect(to: Routes.user_payments_path(conn, :index))
    end
  end
end
