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
        "state" => Phoenix.Token.sign(GlimeshWeb.Endpoint, "stripe state", user.id),
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
      page_title: format_page_title(gettext("Your Payment Portal")),
      can_payments: Accounts.can_use_payments?(user),
      incoming: Payments.sum_incoming(user),
      outgoing: Payments.sum_outgoing(user),
      is_sub_ready_streamer: !is_nil(user.stripe_user_id),
      stripe_oauth_url: stripe_oauth_url,
      platform_subscription: Payments.get_platform_subscription!(user),
      subscriptions: Payments.get_channel_subscriptions(user),
      default_payment_changeset: Accounts.change_stripe_default_payment(user),
      has_payment_method: !is_nil(user.stripe_payment_method),
      payment_history: Payments.list_payment_history(user),
      stripe_dashboard_url: Payments.get_stripe_dashboard_url(user)
    )
  end

  def connect(conn, %{"state" => state, "code" => code}) do
    user = conn.assigns.current_user

    with {:ok, _} <- verify_token(state, user.id),
         {:ok, _} <- Payments.oauth_connect(user, code) do
      conn
      |> put_flash(
        :info,
        gettext("Stripe account linked successfully, welcome to the sub club!")
      )
      |> redirect(to: Routes.user_payments_path(conn, :index))
    else
      {:error, verify_error} when verify_error in [:expired, :invalid] ->
        conn
        |> put_flash(:error, "Your Stripe Connect timed out, please try again.")
        |> redirect(to: Routes.user_payments_path(conn, :index))

      {:error, err} ->
        conn
        |> put_flash(:error, err)
        |> redirect(to: Routes.user_payments_path(conn, :index))
    end
  end

  defp verify_token(state_token, user_id) do
    case Phoenix.Token.verify(GlimeshWeb.Endpoint, "stripe state", state_token, max_age: 86_400) do
      {:ok, found_user_id} ->
        if user_id !== found_user_id do
          {:error, :invalid}
        else
          {:ok, user_id}
        end

      {:error, reason} ->
        {:error, reason}
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
