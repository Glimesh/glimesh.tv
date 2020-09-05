defmodule Glimesh.AppsTest do
  use Glimesh.DataCase

  alias Glimesh.Apps
  import Glimesh.AccountsFixtures

  describe "apps" do
    alias Glimesh.Apps.app()

    @valid_attrs %{
      body_md: "some body_md",
      description: "some description",
      published: true,
      slug: "some slug",
      title: "some title"
    }
    @update_attrs %{
      body_md: "some updated body_md",
      description: "some updated description",
      published: false,
      slug: "some updated slug",
      title: "some updated title"
    }
    @invalid_attrs %{
      body_html: nil,
      body_md: nil,
      description: nil,
      published: nil,
      slug: nil,
      title: nil
    }

    def app_fixture(attrs \\ %{}) do
      {:ok, app} = Apps.create_app(admin_fixture(), attrs |> Enum.into(@valid_attrs))
      app
    end

    test "list_apps/0 returns all apps" do
      app = app_fixture()
      assert Enum.map(Apps.list_apps(), fn x -> x.title end) == [app.title]
    end

    test "get_app!/1 returns the app with given id" do
      app = app_fixture()
      assert Apps.get_app!(app.id).title == app.title
    end

    test "get_app!/1 returns the app with given slug" do
      app = app_fixture()
      assert Apps.get_app_by_slug!(app.slug).title == app.title
    end

    test "create_app/1 with valid data creates a app" do
      assert {:ok, %app{} = app} = Apps.create_app(admin_fixture(), @valid_attrs)
      assert app.body_html == "<p>\nsome body_md</p>\n"
      assert app.body_md == "some body_md"
      assert app.description == "some description"
      assert app.published == true
      assert app.slug == "some slug"
      assert app.title == "some title"
    end

    test "create_app/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Apps.create_app(admin_fixture(), @invalid_attrs)
    end

    test "create_app/1 with no user returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Apps.create_app(nil, @invalid_attrs)
    end

    test "update_app/2 with valid data updates the app" do
      app = app_fixture()
      assert {:ok, %app{} = app} = Apps.update_app(app, @update_attrs)
      assert app.body_html == "<p>\nsome updated body_md</p>\n"
      assert app.body_md == "some updated body_md"
      assert app.description == "some updated description"
      assert app.published == false
      assert app.slug == "some updated slug"
      assert app.title == "some updated title"
    end

    test "update_app/2 with invalid data returns error changeset" do
      app = app_fixture()
      assert {:error, %Ecto.Changeset{}} = Apps.update_app(app, @invalid_attrs)
      assert app.title == Apps.get_app!(app.id).title
    end

    test "change_app/1 returns a app changeset" do
      app = app_fixture()
      assert %Ecto.Changeset{} = Apps.change_app(app)
    end
  end
end
