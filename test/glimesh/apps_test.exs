defmodule Glimesh.AppsTest do
  use Glimesh.DataCase

  import Glimesh.AccountsFixtures

  alias Glimesh.Apps
  alias Glimesh.Apps.App

  @valid_attrs %{
    name: "some name",
    description: "some description",
    homepage_url: "https://glimesh.tv/",
    client: %{
      redirect_uris: "https://glimesh.tv/something\nhttp://localhost:8080/redirect"
    }
  }
  @update_attrs %{
    name: "some updated name",
    description: "some updated description",
    homepage_url: "https://dev.glimesh.tv/",
    client: %{
      redirect_uris: "https://glimesh.tv/something-new"
    }
  }
  @invalid_attrs %{
    name: nil,
    description: nil,
    client: %{
      redirect_uris: nil
    }
  }

  def app_fixture(user, attrs \\ %{}) do
    {:ok, app} = Apps.create_app(user, attrs |> Enum.into(@valid_attrs))
    app
  end

  describe "apps user api" do
    setup do
      {:ok, user: user_fixture()}
    end

    test "list_apps/1 returns user apps", %{user: user} do
      app = app_fixture(user)
      assert Enum.map(Apps.list_apps(user), fn x -> x.name end) == [app.name]
    end

    test "get_app/2 returns the app with given id", %{user: user} do
      app = app_fixture(user)
      {:ok, found_app} = Apps.get_app(user, app.id)
      assert found_app.name == app.name
    end

    test "create_app/2 with valid data creates a app", %{user: user} do
      assert {:ok, %App{} = app} = Apps.create_app(user, @valid_attrs)
      assert app.name == "some name"
      assert app.description == "some description"
      assert app.homepage_url == "https://glimesh.tv/"
    end

    test "create_app/2 with string keys and atom keys creates an app", %{user: user} do
      # Atom keys
      assert {:ok, %App{} = app} = Apps.create_app(user, @valid_attrs)
      assert app.name == "some name"
      assert app.description == "some description"
      assert app.homepage_url == "https://glimesh.tv/"

      # String Keys
      assert {:ok, %App{} = app} =
               Apps.create_app(user, %{
                 "name" => "some name",
                 "description" => "some description",
                 "homepage_url" => "https://glimesh.tv/",
                 "client" => %{
                   "redirect_uris" => "https://glimesh.tv/something"
                 }
               })

      assert app.name == "some name"
      assert app.description == "some description"
      assert app.homepage_url == "https://glimesh.tv/"
    end

    test "create_app/2 creates an oauth application", %{user: user} do
      assert {:ok, %App{} = app} = Apps.create_app(user, @valid_attrs)

      assert app.client.name == "some name"
    end

    test "create_app/2 with invalid data returns error changeset", %{user: user} do
      assert {:error, %Ecto.Changeset{}} = Apps.create_app(user, @invalid_attrs)
    end

    test "update_app/3 with valid data updates the app", %{user: user} do
      app = app_fixture(user)
      assert {:ok, %App{} = app} = Apps.update_app(user, app, @update_attrs)
      assert app.name == "some updated name"
      assert app.description == "some updated description"
      assert app.homepage_url == "https://dev.glimesh.tv/"
    end

    test "update_app/3 with valid data updates the oauth app", %{user: user} do
      app = app_fixture(user)
      assert {:ok, %App{} = app} = Apps.update_app(user, app, @update_attrs)
      assert app.client.name == "some updated name"
      assert app.client.redirect_uris == ["https://glimesh.tv/something-new"]
    end

    test "update_app/3 with invalid data returns error changeset with all errors", %{user: user} do
      app = app_fixture(user)
      update = Apps.update_app(user, app, @invalid_attrs)
      assert {:error, %Ecto.Changeset{} = changeset} = update

      assert changeset.errors[:name] == {"can't be blank", [validation: :required]}
      assert changeset.errors[:description] == {"can't be blank", [validation: :required]}

      assert changeset.changes[:client].errors[:redirect_uris] ==
               {"can't be blank", [validation: :required]}

      {:ok, found_app} = Apps.get_app(user, app.id)
      assert app.name == found_app.name
    end

    test "rotate_app/2 rotates public / secret keys", %{user: user} do
      app = app_fixture(user)
      {:ok, new_oauth_app} = Apps.rotate_oauth_app(user, app)
      assert app.client.id != new_oauth_app.id
      assert app.client.secret != new_oauth_app.secret
    end

    test "create_app/2 with non-localhost non-ssl fails", %{user: user} do
      assert {:error, %Ecto.Changeset{} = changeset} =
               Apps.create_app(user, %{
                 name: "some name",
                 description: "some description",
                 homepage_url: "https://glimesh.tv/",
                 client: %{
                   redirect_uris: "http://example.com/something"
                 }
               })

      assert changeset.changes[:client].errors[:redirect_uris] ==
               {"If using unsecure http, you must be using a local loopback address like [localhost, 127.0.0.1, ::1]",
                []}
    end
  end

  describe "apps system api" do
    test "list_apps/0 returns all apps" do
      app = app_fixture(user_fixture())
      assert Enum.map(Apps.list_apps(), fn x -> x.name end) == [app.name]
    end

    test "change_app/1 returns a app changeset" do
      assert %Ecto.Changeset{} = Apps.change_app(%App{})
    end
  end

  describe "admin permissions" do
    setup do
      {:ok, user: user_fixture(), admin: admin_fixture()}
    end

    test "get_app/2 returns the app with given id", %{user: user, admin: admin} do
      app = app_fixture(user)
      {:ok, found_app} = Apps.get_app(admin, app.id)
      assert found_app.name == app.name
    end

    test "update_app/3 with valid data updates the app", %{user: user, admin: admin} do
      app = app_fixture(user)
      assert {:ok, %App{} = app} = Apps.update_app(admin, app, @update_attrs)
      assert app.name == "some updated name"
    end
  end

  describe "core apps validators" do
    @redirect_uri_validators [
      {"http://localhost/", {:ok, "localhost"}},
      {"http://127.0.0.1/", {:ok, "127.0.0.1"}},
      {"http://[::1]/", {:ok, "::1"}},
      {"http://localhost:8080/", {:ok, "localhost"}},
      {"http://example.com/",
       {:error,
        "If using unsecure http, you must be using a local loopback address like [localhost, 127.0.0.1, ::1]"}},
      {"https://example.com/", {:ok, "example.com"}}
    ]

    ExUnit.Case.register_attribute(__ENV__, :pair)

    for {lhs, rhs} <- @redirect_uri_validators do
      @pair {lhs, rhs}

      test "validate_localhost_http_url: #{lhs}", context do
        {l, r} = context.registered.pair

        out = Glimesh.Apps.App.validate_localhost_http_url(l)

        assert out == r
      end
    end
  end
end
