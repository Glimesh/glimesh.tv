defmodule GlimeshWeb.SupportModalTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glimesh.AccountsFixtures

  describe "Support Modal with Sub Button" do
    setup [:register_and_log_in_user]

    test "sub button doesn't show by default", %{conn: conn, user: user} do
      streamer = streamer_fixture()

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.SupportModal,
          session: %{"streamer" => streamer, "user" => user}
        )

      refute view |> element("button", "Support") |> render_click() =~ "Subscribe"
    end

    test "sub button shows up when enabled", %{conn: conn, user: user} do
      streamer = setup_sub_streamer(streamer_fixture())

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.SupportModal,
          session: %{"streamer" => streamer, "user" => user}
        )

      assert view |> element("button", "Support") |> render_click() =~ "Subscribe"
    end
  end

  describe "Support Modal with Streamloots" do
    setup [:register_and_log_in_user]

    test "streamloots button doesn't show by default", %{conn: conn, user: user} do
      streamer = streamer_fixture()

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.SupportModal,
          session: %{"streamer" => streamer, "user" => user}
        )

      refute view |> element("button", "Support") |> render_click() =~ "Streamloots"
    end

    test "streamloots shows up when enabled", %{conn: conn, user: user} do
      streamer = setup_streamloots_streamer(streamer_fixture())

      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.SupportModal,
          session: %{"streamer" => streamer, "user" => user}
        )

      assert view |> element("button", "Support") |> render_click() =~ "Streamloots"
    end
  end

  defp setup_sub_streamer(%Glimesh.Accounts.User{} = streamer) do
    {:ok, streamer} =
      Glimesh.Accounts.set_stripe_attrs(streamer, %{
        is_stripe_setup: true,
        is_tax_verified: true
      })

    streamer
  end

  defp setup_streamloots_streamer(%Glimesh.Accounts.User{} = streamer) do
    {:ok, _channel} =
      Glimesh.Streams.update_addons(streamer, streamer.channel, %{
        "streamloots_url" => "https://www.streamloots.com/ferret"
      })

    Glimesh.Accounts.get_user!(streamer.id)
  end
end
