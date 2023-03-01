defmodule GlimeshWeb.UserApplicationsTest do
  use GlimeshWeb.ConnCase

  alias Glimesh.Apps
  import Glimesh.AccountsFixtures

  @create_attrs %{
    name: "some name",
    description: "some description",
    homepage_url: "https://glimesh.tv/",
    client: %{
      redirect_uris: "https://glimesh.tv/something"
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

  describe "user without ownership of the app" do
    setup [:register_and_log_in_user]

    test "does not render show page", %{conn: conn} do
      # Fixture for a different random user
      {:ok, app} = Apps.create_app(user_fixture(), @create_attrs)

      conn = get(conn, ~p"/users/settings/applications/#{app.id}")
      assert response(conn, 403)
    end

    test "does not render edit form", %{conn: conn} do
      # Fixture for a different random user
      {:ok, app} = Apps.create_app(user_fixture(), @create_attrs)

      conn = get(conn, ~p"/users/settings/applications/#{app.id}/edit")
      assert response(conn, 403)
    end

    test "does not allow updating", %{conn: conn} do
      # Fixture for a different random user
      {:ok, app} = Apps.create_app(user_fixture(), @create_attrs)

      conn = put(conn, ~p"/users/settings/applications/#{app.id}", app: @update_attrs)
      assert response(conn, 403)
    end

    test "cannot rotate the keys", %{conn: conn} do
      # Fixture for a different random user
      {:ok, app} = Apps.create_app(user_fixture(), @create_attrs)

      conn = put(conn, ~p"/users/settings/applications/#{app.id}/rotate")
      assert response(conn, 403)
    end
  end

  setup :register_and_log_in_user

  describe "index" do
    test "lists all apps", %{conn: conn} do
      conn = get(conn, ~p"/users/settings/applications")
      assert html_response(conn, 200) =~ "Applications"
    end
  end

  describe "new app" do
    test "renders form", %{conn: conn} do
      conn = get(conn, ~p"/users/settings/applications/new")
      assert html_response(conn, 200) =~ "Create Application"
    end
  end

  describe "create app" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/users/settings/applications", app: @create_attrs)

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == ~p"/users/settings/applications/#{id}"

      conn = get(conn, ~p"/users/settings/applications/#{id}")
      assert html_response(conn, 200) =~ "some name"
      assert html_response(conn, 200) =~ "https://glimesh.tv/something"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/users/settings/applications", app: @invalid_attrs)
      assert html_response(conn, 200) =~ "Create Application"
    end
  end

  describe "edit app" do
    setup [:create_app]

    test "renders form for editing chosen app", %{conn: conn, app: app} do
      conn = get(conn, ~p"/users/settings/applications/#{app.id}/edit")
      assert html_response(conn, 200) =~ "Edit Application"
    end
  end

  describe "update app" do
    setup [:create_app]

    test "redirects when data is valid", %{conn: conn, app: app} do
      conn = put(conn, ~p"/users/settings/applications/#{app.id}", app: @update_attrs)

      assert redirected_to(conn) == ~p"/users/settings/applications/#{app.id}"

      conn = get(conn, ~p"/users/settings/applications/#{app.id}")
      assert html_response(conn, 200) =~ "some updated name"
      assert html_response(conn, 200) =~ app.client.secret
    end

    test "rotates the keys when user requests", %{conn: conn, user: user, app: app} do
      conn = put(conn, ~p"/users/settings/applications/#{app.id}/rotate")
      assert redirected_to(conn) == ~p"/users/settings/applications/#{app.id}"

      {:ok, new_app} = Glimesh.Apps.get_app(user, app.id)
      conn = get(conn, ~p"/users/settings/applications/#{app.id}")
      refute html_response(conn, 200) =~ app.client.secret
      assert html_response(conn, 200) =~ new_app.client.secret
    end

    test "renders errors when data is invalid", %{conn: conn, app: app} do
      conn = put(conn, ~p"/users/settings/applications/#{app.id}", app: @invalid_attrs)

      assert html_response(conn, 200) =~ "Edit Application"
    end
  end

  defp create_app(%{user: user}) do
    {:ok, app} = Apps.create_app(user, @create_attrs)

    %{app: app}
  end
end
