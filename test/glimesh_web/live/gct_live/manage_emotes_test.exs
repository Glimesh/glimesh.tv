defmodule GlimeshWeb.GctLive.ManageEmotesTest do
  use GlimeshWeb.ConnCase

  import Phoenix.LiveViewTest

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

      assert view |> form("#emote_upload", )
      assert render_submit(view, %{"0" => "glimchef"}) =~ "Successfully uploaded emotes"
    end
  end
end
