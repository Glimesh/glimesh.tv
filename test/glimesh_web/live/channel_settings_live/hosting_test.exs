defmodule GlimeshWeb.ChannelSettingsLive.HostingTest do
  use GlimeshWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  describe "Allow Hosting Settings" do
    setup [:register_and_log_in_streamer_that_can_host]

    test "can set allow hosting", %{conn: conn, user: user, channel: channel} do
      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.Hosting, session: %{"user" => user})

      form = view |> element(".form_allow_hosting")

      assert render_change(form, %{
               "channel" => %{"allow_hosting" => "true"}
             }) =~
               "Saved Hosting Preference."

      assert Glimesh.ChannelLookups.get_channel!(channel.id).allow_hosting == true
    end

    test "can set disallow hosting", %{conn: conn, user: user, channel: channel} do
      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.Hosting, session: %{"user" => user})

      form = view |> element(".form_allow_hosting")

      assert render_change(form, %{
               "channel" => %{"allow_hosting" => "false"}
             }) =~
               "Saved Hosting Preference."

      assert Glimesh.ChannelLookups.get_channel!(channel.id).allow_hosting == false
    end
  end

  defp create_hosting_target_data(_) do
    %{
      target_allowed_hosting:
        Glimesh.AccountsFixtures.streamer_fixture(%{}, %{allow_hosting: true})
    }
  end

  describe "New Add Host Settings" do
    setup [:register_and_log_in_streamer_that_can_host, :create_hosting_target_data]

    test "can find a channel to host", %{
      conn: conn,
      user: user,
      target_allowed_hosting: target_channel
    } do
      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.Hosting, session: %{"user" => user})

      view
      |> element(".form_add_channel")
      |> render_change(%{"suggest" => %{"add_channel" => "user"}})

      assert has_element?(view, "#channel-lookup-#{target_channel.id}")
    end

    test "can host a channel", %{conn: conn, target_allowed_hosting: target_channel} do
      {:ok, view, _html} = live(conn, Routes.user_settings_path(conn, :hosting))

      render_hook(view, :add_channel_selection_made, %{
        user_id: target_channel.id,
        username: target_channel.displayname,
        channel_id: target_channel.channel.id
      })

      assert {:ok, conn} =
               view
               |> element("#add-channel-button")
               |> render_click()
               |> follow_redirect(conn, Routes.user_settings_path(conn, :hosting))

      assert html_response(conn, 200) =~ "Channel added"

      {:ok, redirected_view, _html} = live(conn)
      assert has_element?(redirected_view, "#hosted-row-#{target_channel.channel.id}")
    end

    test "can host a channel without using the picker", %{
      conn: conn,
      target_allowed_hosting: target_channel
    } do
      {:ok, view, _html} = live(conn, Routes.user_settings_path(conn, :hosting))

      assert {:ok, conn} =
               view
               |> element("#add-channel-button")
               |> render_click(%{"name" => target_channel.displayname, "selected" => ""})
               |> follow_redirect(conn, Routes.user_settings_path(conn, :hosting))

      assert html_response(conn, 200) =~ "Channel added"

      {:ok, redirected_view, _html} = live(conn)
      assert has_element?(redirected_view, "#hosted-row-#{target_channel.channel.id}")
    end
  end

  defp associate_already_hosted_data(%{conn: conn}) do
    hosting_target_ready = Glimesh.AccountsFixtures.streamer_fixture(%{}, %{allow_hosting: true})
    hosting_target_error = Glimesh.AccountsFixtures.streamer_fixture(%{}, %{allow_hosting: true})
    hosting_target_active = Glimesh.AccountsFixtures.streamer_fixture(%{}, %{allow_hosting: true})

    %{conn: conn, user: user, channel: channel} =
      register_and_log_in_streamer_that_can_host(%{conn: conn})

    channel_host =
      Glimesh.Streams.ChannelHosts.add_new_host(
        user,
        channel,
        %Glimesh.Streams.ChannelHosts{
          hosting_channel_id: channel.id,
          target_channel_id: hosting_target_ready.channel.id,
          status: "ready"
        },
        %{}
      )

    Glimesh.Streams.ChannelHosts.add_new_host(
      user,
      channel,
      %Glimesh.Streams.ChannelHosts{
        hosting_channel_id: channel.id,
        target_channel_id: hosting_target_error.channel.id,
        status: "error"
      },
      %{}
    )

    Glimesh.Streams.ChannelHosts.add_new_host(
      user,
      channel,
      %Glimesh.Streams.ChannelHosts{
        hosting_channel_id: channel.id,
        target_channel_id: hosting_target_active.channel.id,
        status: "hosting"
      },
      %{}
    )

    %{
      conn: conn,
      user: user,
      channel: channel,
      hosting_target_ready: hosting_target_ready,
      hosting_target_error: hosting_target_error,
      hosting_target_active: hosting_target_active,
      channel_host_ready: channel_host
    }
  end

  describe "Existing add hosts settings" do
    setup [:associate_already_hosted_data]

    test "Hosted channels appear on the setup page with proper status",
         %{
           conn: conn,
           user: user,
           hosting_target_ready: ready_target,
           hosting_target_error: error_target,
           hosting_target_active: active_target
         } do
      {:ok, view, _html} =
        live_isolated(conn, GlimeshWeb.ChannelSettingsLive.Hosting, session: %{"user" => user})

      assert has_element?(view, "#hosted-row-#{ready_target.channel.id}")
      assert has_element?(view, "#hosted-row-#{error_target.channel.id}")
      assert has_element?(view, "#hosted-row-#{active_target.channel.id}")
      assert has_element?(view, "#hosted-row-#{ready_target.channel.id}-status > .fa-check")

      assert has_element?(
               view,
               "#hosted-row-#{error_target.channel.id}-status > .fa-times-circle"
             )

      assert has_element?(view, "#hosted-row-#{active_target.channel.id}-status > .fa-tv")
    end

    test "Can remove hosted channels", %{conn: conn, hosting_target_ready: target} do
      {:ok, view, _html} = live(conn, Routes.user_settings_path(conn, :hosting))

      assert {:ok, conn} =
               view
               |> element("#remove-channel-button-#{target.channel.id}")
               |> render_click()
               |> follow_redirect(conn, Routes.user_settings_path(conn, :hosting))

      assert html_response(conn, 200) =~ "Hosting target removed"

      {:ok, redirected_view, _html} = live(conn)
      refute has_element?(redirected_view, "#hosted-row-#{target.channel.id}")
    end
  end

  describe "Can't host others" do
    test "when you haven't streamed enough", %{conn: conn} do
      user =
        Glimesh.AccountsFixtures.streamer_fixture()
        |> Glimesh.AccountsFixtures.change_inserted_at_for_user(
          NaiveDateTime.add(NaiveDateTime.utc_now(), 86_400 * -6)
          |> NaiveDateTime.truncate(:second)
        )

      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, Routes.user_settings_path(conn, :hosting))

      refute has_element?(view, "#add-channel-button")
      assert has_element?(view, "#not-qualified")
    end

    test "when your account isn't old enough", %{conn: conn} do
      user = Glimesh.AccountsFixtures.streamer_fixture()

      Glimesh.Streams.create_stream(user.channel, %{
        started_at:
          NaiveDateTime.add(NaiveDateTime.utc_now(), 60 * 60 * -10)
          |> NaiveDateTime.truncate(:second),
        ended_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })

      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, Routes.user_settings_path(conn, :hosting))

      refute has_element?(view, "#add-channel-button")
      assert has_element?(view, "#not-qualified")
    end

    test "when your account isn't email verified", %{conn: conn} do
      user =
        Glimesh.AccountsFixtures.streamer_fixture()
        |> Glimesh.AccountsFixtures.change_inserted_at_for_user(
          NaiveDateTime.add(NaiveDateTime.utc_now(), 86_400 * -6)
          |> NaiveDateTime.truncate(:second)
        )

      user
      |> Ecto.Changeset.change(%{confirmed_at: nil})
      |> Glimesh.Repo.update()

      Glimesh.Streams.create_stream(user.channel, %{
        started_at:
          NaiveDateTime.add(NaiveDateTime.utc_now(), 60 * 60 * -10)
          |> NaiveDateTime.truncate(:second),
        ended_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
      })

      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, Routes.user_settings_path(conn, :hosting))

      refute has_element?(view, "#add-channel-button")
      assert has_element?(view, "#not-qualified")
    end
  end
end
