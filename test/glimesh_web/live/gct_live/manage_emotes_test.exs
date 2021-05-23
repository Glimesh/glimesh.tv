defmodule GlimeshWeb.GctLive.ManageEmotesTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest
  import Glimesh.AccountsFixtures

  @glimchef %{
    last_modified: 1_594_171_879_000,
    name: "glimchef.svg",
    content: File.read!("test/assets/glimchef.svg"),
    size: 19_056,
    type: "image/svg+xml"
  }

  describe "Emotes Management" do
    setup [:register_and_log_in_gct_user]

    test "can upload emotes", %{conn: conn} do
      {:ok, view, _} = live(conn, Routes.gct_manage_emotes_path(conn, :index))

      avatar =
        file_input(view, "#emote_upload", :emote, [
          @glimchef
        ])

      IO.inspect(avatar)

      assert render_upload(avatar, "glimchef.svg") =~ "glimchef"

      form = view |> element("form")

      assert render_submit(form, %{"0" => "glimchef"}) =~ "Successfully uploaded emotes"
    end

    test "cannot upload duplicate emotes", %{conn: conn} do
      {:ok, _} =
        Glimesh.Emotes.create_global_emote(admin_fixture(), %{
          emote: "glimchef",
          animated: false,
          static_file: %Plug.Upload{
            content_type: "image/svg+xml",
            path: "test/assets/glimchef.svg",
            filename: "glimchef.svg"
          }
        })

      {:ok, view, _} = live(conn, Routes.gct_manage_emotes_path(conn, :index))

      avatar =
        file_input(view, "#emote_upload", :emote, [
          @glimchef
        ])

      assert render_upload(avatar, "glimchef.svg") =~ "glimchef"
      form = view |> element("form")

      assert render_submit(form, %{"0" => "glimchef"}) =~ "Successfully uploaded emotes"

      # assert view |> form("#emote_upload", )
      # assert render_submit(view, %{"0" => "glimchef"}) =~ "Successfully uploaded emotes"
    end
  end
end
