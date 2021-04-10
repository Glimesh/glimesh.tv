defmodule GlimeshWeb.AboutControllerTest do
  use GlimeshWeb.ConnCase

  describe "about pages work and show content" do
    test "shows the about glimesh page", %{conn: conn} do
      conn = get(conn, Routes.about_path(conn, :index))
      assert html_response(conn, 200) =~ "Welcome to Glimesh"
    end

    test "shows the streaming page", %{conn: conn} do
      conn = get(conn, Routes.about_path(conn, :streaming))
      assert html_response(conn, 200) =~ "Streaming on Glimesh"
    end

    test "shows the the team page", %{conn: conn} do
      conn = get(conn, Routes.about_path(conn, :team))
      assert html_response(conn, 200) =~ "The Glimesh Team is a core group"
    end

    test "shows the our mission page", %{conn: conn} do
      conn = get(conn, Routes.about_path(conn, :mission))

      assert html_response(conn, 200) =~
               "Our mission at Glimesh is to create a platform of sustainability, where every content creator has a fair oppourtunity to grow and create an income, while being given simple and powerful tools they can rely on."
    end

    test "shows the alpha page", %{conn: conn} do
      conn = get(conn, Routes.about_path(conn, :alpha))

      assert html_response(conn, 200) =~
               "We are very excited to be launching the Alpha version of Glimesh and we&#39;re proud to say that all of our alpha features will be available to everyone!"
    end
  end

  describe "streaming page for logged in user" do
    setup :register_and_log_in_user

    test "shows customize your channel button", %{conn: conn} do
      conn = get(conn, Routes.about_path(conn, :streaming))
      assert html_response(conn, 200) =~ "Customize Your Channel"
    end
  end

  describe "about pages with other layouts work and show contents" do
    test "shows the about faq page", %{conn: conn} do
      conn = get(conn, Routes.about_path(conn, :faq))
      assert html_response(conn, 200) =~ "What’s Glimesh?"
    end

    test "shows the privacy policy page", %{conn: conn} do
      conn = get(conn, Routes.about_path(conn, :privacy))

      assert html_response(conn, 200) =~
               "This Privacy Policy explains how your personal information is collected, used, and disclosed by Glimesh, its subsidiaries, and affiliated companies (“Glimesh”)."
    end

    test "shows the terms of service page", %{conn: conn} do
      conn = get(conn, Routes.about_path(conn, :terms))

      assert html_response(conn, 200) =~
               "We reserve the right, at our sole discretion, to change or modify portions of these Terms of Service at any time."
    end

    test "shows the dmca page", %{conn: conn} do
      conn = get(conn, Routes.about_path(conn, :dmca))

      assert html_response(conn, 200) =~ "Glimesh DMCA Policies"
    end

    test "shows the credits page", %{conn: conn} do
      conn = get(conn, Routes.about_path(conn, :credits))

      assert html_response(conn, 200) =~ "Glimesh Credits"
    end
  end
end
