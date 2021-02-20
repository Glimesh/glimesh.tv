defmodule GlimeshWeb.SubscriptionCase do
  use ExUnit.CaseTemplate

  import Phoenix.ChannelTest, only: [connect: 2]
  import Glimesh.AccountsFixtures

  @endpoint GlimeshWeb.Endpoint

  using do
    quote do
      # Import conveniences for testing with channels
      use GlimeshWeb.ChannelCase
      use Absinthe.Phoenix.SubscriptionTest, schema: Glimesh.Schema

      import GlimeshWeb.SubscriptionCase
    end
  end

  def setup_socket(_) do
    user = user_fixture()

    {:ok, %{token: token}} =
      ExOauth2Provider.AccessTokens.create_token(user, %{scopes: "public email chat streamkey"},
        otp_app: :glimesh
      )

    {:ok, socket} =
      connect(GlimeshWeb.ApiSocket, %{
        "token" => token
      })

    {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)

    %{
      socket: socket,
      user: user
    }
  end
end
