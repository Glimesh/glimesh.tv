defmodule GlimeshWeb.GctController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias Glimesh.Payments

  #General Routes
  def index(conn, _params) do
    render(conn, "index.html")
  end

  def username_lookup(conn, params) do
    user = Accounts.get_by_username(params["query"], true)
    render(
      conn,
      "lookup_user.html",
      user: user,
      payout_history: Payments.list_payout_history(user),
      payment_history: Payments.list_payment_history(user))
  end

end
