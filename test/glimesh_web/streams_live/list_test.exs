defmodule GlimeshWeb.StreamsLive.ListTest do
  use GlimeshWeb.ConnCase

  import Glimesh.AccountsFixtures
  import Phoenix.LiveViewTest

  defp create_channel(_) do
    category = Glimesh.ChannelCategories.get_category("gaming")

    {:ok, subcategory} =
      Glimesh.ChannelCategories.create_subcategory(%{
        name: "Testing",
        category_id: category.id
      })

    streamer =
      streamer_fixture(%{}, %{
        # Force ourselves to have a gaming stream
        category_id: category.id,
        subcategory_id: subcategory.id
      })

    Glimesh.Streams.start_stream(streamer.channel)

    %{
      subcategory: subcategory,
      category: category,
      channel: streamer.channel,
      streamer: streamer
    }
  end

  describe "Streams List" do
    setup :create_channel

    test "lists some streams", %{
      conn: conn,
      channel: channel,
      streamer: streamer,
      category: category
    } do
      Glimesh.Streams.start_stream(channel)

      {:ok, _, html} = live(conn, Routes.streams_list_path(conn, :index, category.slug))

      assert html =~ "#{category.name} Streams"
      assert html =~ streamer.displayname
      assert html =~ channel.title
    end

    test "lists some streams and shows new streamer badge", %{
      conn: conn,
      channel: channel,
      streamer: streamer,
      category: category
    } do
      random_stream =
        streamer_fixture(%{}, %{
          category_id: category.id,
          is_new_streamer: true
        })

      Glimesh.Streams.start_stream(random_stream.channel)

      {:ok, _, html} = live(conn, Routes.streams_list_path(conn, :index, category.slug))

      assert html =~ "#{category.name} Streams"
      assert html =~ streamer.displayname
      assert html =~ channel.title
      assert html =~ "new-streamer-badge"
    end

    test "can filter streams by tags", %{
      conn: conn,
      category: category,
      channel: channel
    } do
      random_stream =
        streamer_fixture(%{}, %{
          category_id: category.id
        })

      Glimesh.Streams.start_stream(random_stream.channel)

      tag = tag_fixture(%{name: "Some Tag", category_id: category.id})

      {:ok, channel} =
        channel
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:tags, [tag])
        |> Glimesh.Repo.update()

      {:ok, view, html} = live(conn, Routes.streams_list_path(conn, :index, category.slug))

      assert html =~ "Showing 2 of 2 Live Channels"

      html =
        render_change(view, "filter_change", %{
          "form" => %{
            "subcategory_search" => "",
            "language" => "",
            "tag_search" => Jason.encode!([%{"slug" => tag.slug}])
          }
        })

      assert html =~ "#{category.name} Streams"
      assert html =~ "Showing 1 of 2 Live Channels"
      assert html =~ tag.name
      assert html =~ channel.title
    end

    test "can filter streams by subcategory", %{
      conn: conn,
      category: category,
      subcategory: subcategory,
      channel: channel
    } do
      random_stream =
        streamer_fixture(%{}, %{
          category_id: category.id
        })

      Glimesh.Streams.start_stream(random_stream.channel)

      {:ok, view, html} = live(conn, Routes.streams_list_path(conn, :index, category.slug))

      assert html =~ "Showing 2 of 2 Live Channels"

      html =
        render_change(view, "filter_change", %{
          "form" => %{
            "tag_search" => "",
            "language" => "",
            "subcategory_search" => Jason.encode!([%{"slug" => subcategory.slug}])
          }
        })

      assert html =~ "#{category.name} Streams"
      assert html =~ "Showing 1 of 2 Live Channels"
      assert html =~ subcategory.name
      assert html =~ channel.title
    end

    test "can filter streams by new streamers", %{
      conn: conn,
      category: category,
      subcategory: subcategory,
      channel: channel
    } do
      random_stream =
        streamer_fixture(%{}, %{
          category_id: category.id,
          is_new_streamer: true
        })

      Glimesh.Streams.start_stream(random_stream.channel)

      {:ok, view, html} = live(conn, Routes.streams_list_path(conn, :index, category.slug))

      assert html =~ "Showing 2 of 2 Live Channels"
      assert html =~ "new-streamer-badge"

      html =
        render_change(view, "filter_change", %{
          "form" => %{
            "tag_search" => "",
            "language" => "",
            "subcategory_search" => "",
            "is_new_streamer" => "true"
          }
        })

      assert html =~ "#{category.name} Streams"
      assert html =~ "Showing 1 of 2 Live Channels"
      assert html =~ subcategory.name
      assert html =~ channel.title
      assert html =~ "new-streamer-badge"
    end

    test "can show more streams if necessary", %{
      conn: conn,
      category: category,
      subcategory: subcategory
    } do
      {:ok, second_subcategory} =
        Glimesh.ChannelCategories.create_subcategory(%{
          name: "Something Else",
          category_id: category.id
        })

      Enum.each(1..6, fn _ ->
        random_stream =
          streamer_fixture(%{}, %{
            category_id: category.id,
            subcategory_id: second_subcategory.id
          })

        Glimesh.Streams.start_stream(random_stream.channel)
      end)

      Enum.each(1..20, fn _ ->
        random_stream =
          streamer_fixture(%{}, %{
            category_id: category.id,
            subcategory_id: subcategory.id
          })

        Glimesh.Streams.start_stream(random_stream.channel)
      end)

      {:ok, view, html} = live(conn, Routes.streams_list_path(conn, :index, category.slug))
      assert html =~ "Showing 27 of 27 Live Channels"

      html =
        render_change(view, "filter_change", %{
          "form" => %{
            "tag_search" => "",
            "language" => "",
            "subcategory_search" =>
              Jason.encode!([
                %{"slug" => subcategory.slug},
                %{"slug" => second_subcategory.slug}
              ])
          }
        })

      # 6 for each category
      assert html =~ "Showing 12 of 27 Live Channels"
      assert html =~ subcategory.name
      assert html =~ second_subcategory.name
      assert html =~ "Show more stream"

      assert view
             |> element("button", "Show more streams")
             |> render_click() =~ "Showing 27 of 27 Live Channels"
    end
  end
end
