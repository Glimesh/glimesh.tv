defmodule GlimeshWeb.GctControllerTest do
  use GlimeshWeb.ConnCase

  alias Glimesh.CommunityTeam
  import Glimesh.AccountsFixtures


  describe "index while gct" do
    setup :register_and_log_in_gct_user

    test "show index page", %{conn: conn} do
      conn = get(conn, Routes.gct_path(conn, :index))
      assert html_response(conn, 200) =~ "Glimesh Community Team Dashboard"
    end
  end

  describe "index while not gct" do

    test "redirect user", %{conn: conn} do
      conn = get(conn, Routes.gct_path(conn, :index))
      assert html_response(conn, 302) =~ "You are being"
    end
  end

  describe "index while gct without tfa" do
    setup :register_and_log_in_gct_user_without_tfa

    test "redirect user", %{conn: conn} do
      conn = get(conn, Routes.gct_path(conn, :index))
      assert html_response(conn, 302) =~ "You are being"
    end
  end

  describe "lookup user" do
    setup :register_and_log_in_gct_user

    test "valid user returns information", %{conn: conn} do
      lookup_user = user_fixture()
      conn = get(conn, Routes.gct_path(conn, :username_lookup, query: lookup_user.username))
      assert html_response(conn, 200) =~ "Information for " <> lookup_user.displayname
    end

    test "invalid user returns an invalid user page", %{conn: conn} do
      conn = get(conn, Routes.gct_path(conn, :username_lookup, query: "invalid_user"))
      assert html_response(conn, 200) =~ "User does not exist"
    end
  end

  describe "edit user profile" do
    setup :register_and_log_in_gct_user

    test "valid user returns edit page", %{conn: conn} do
      valid_user = user_fixture()
      conn = get(conn, Routes.gct_path(conn, :edit_user_profile, valid_user.username))
      assert html_response(conn, 200) =~ valid_user.displayname
    end

    test "invalid user returns invalid user page", %{conn: conn} do
      conn = get(conn, Routes.gct_path(conn, :edit_user_profile, "invalid_user"))
      assert html_response(conn, 200) =~ "User does not exist"
    end
  end

  describe "edit user" do
    setup :register_and_log_in_gct_user

    test "valid user returns edit page", %{conn: conn} do
      valid_user = user_fixture()
      conn = get(conn, Routes.gct_path(conn, :edit_user, valid_user.username))
      assert html_response(conn, 200) =~ valid_user.username
    end

    test "invalid user returns invalid user page", %{conn: conn} do
      conn = get(conn, Routes.gct_path(conn, :edit_user, "invalid_user"))
      assert html_response(conn, 200) =~ "User does not exist"
    end
  end
end
