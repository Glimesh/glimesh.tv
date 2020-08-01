defmodule GlimeshWeb.UserPaymentsController do
  use GlimeshWeb, :controller

  alias Glimesh.Accounts
  alias GlimeshWeb.UserAuth

  def index(conn, _params) do
    # client_id=ca_32D88BD1qLklliziD7gYQvctJIhWBSQ7&
    # state={STATE_VALUE}&
    # suggested_capabilities[]=transfers&
    # stripe_user[email]=user@example.com
    params = URI.encode_query(%{
      "client_id" => Application.get_env(:stripity_stripe, :public_api_key),
      "state" => Plug.CSRFProtection.get_csrf_token(),
      "suggested_capabilities" => "transfers,card_payments",
      "stripe_user[email]" => "luke@axxim.net"
    })
    stripe_oauth_url = "https://connect.stripe.com/express/oauth/authorize?" <> params

    render(conn, "index.html", stripe_oauth_url: stripe_oauth_url)
  end

end
