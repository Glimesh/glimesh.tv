defmodule GlimeshWeb.AboutControllerTest do
  use GlimeshWeb.ConnCase

  describe "about pages work and show content" do
    test "shows the about glimesh page", %{conn: conn} do
      conn = get(conn, ~p"/about")
      assert html_response(conn, 200) =~ "Welcome to Glimesh"
    end

    test "shows the streaming page", %{conn: conn} do
      conn = get(conn, ~p"/about/streaming")
      assert html_response(conn, 200) =~ "Streaming on Glimesh"
    end

    test "shows the the team page", %{conn: conn} do
      conn = get(conn, ~p"/about/team")
      assert html_response(conn, 200) =~ "Glimesh is not quite like a traditional company!"
    end

    test "shows the our mission page", %{conn: conn} do
      conn = get(conn, ~p"/about/mission")

      assert html_response(conn, 200) =~
               "Our mission at Glimesh is to create a platform of sustainability, where every content creator has a fair oppourtunity to grow and create an income, while being given simple and powerful tools they can rely on."
    end

    test "shows the alpha page", %{conn: conn} do
      conn = get(conn, ~p"/about/alpha")

      assert html_response(conn, 200) =~
               "We are very excited to be launching the Alpha version of Glimesh and we&#39;re proud to say that all of our alpha features will be available to everyone!"
    end
  end

  describe "streaming page for logged in user" do
    setup :register_and_log_in_user

    test "shows customize your channel button", %{conn: conn} do
      conn = get(conn, ~p"/about/streaming")
      assert html_response(conn, 200) =~ "Customize Your Channel"
    end
  end

  describe "about pages with other layouts work and show contents" do
    test "shows the about faq page", %{conn: conn} do
      conn = get(conn, ~p"/about/faq")
      assert html_response(conn, 200) =~ "What’s Glimesh?"
    end

    test "shows the privacy policy page", %{conn: conn} do
      conn = get(conn, ~p"/about/privacy")

      assert html_response(conn, 200) =~
               "We take the protection of your (“You”, “Your”) private information and right to privacy seriously and have created this Policy to the best of our ability for the current stage of development."
    end

    test "shows the cookie policy page", %{conn: conn} do
      conn = get(conn, ~p"/about/cookies")

      assert html_response(conn, 200) =~
               "This cookie policy explains how Glimesh (“Glimesh”, “We”, “Us”, “Our”) uses cookies to recognize when you visit our Our website"
    end

    test "shows the terms of service page", %{conn: conn} do
      conn = get(conn, ~p"/about/terms")

      assert html_response(conn, 200) =~
               "We reserve the right, at our sole discretion, to change or modify portions of these Terms of Service at any time."
    end

    test "shows the dmca page", %{conn: conn} do
      conn = get(conn, ~p"/about/dmca")

      assert html_response(conn, 200) =~ "Glimesh DMCA Policies"
    end

    test "shows the credits page", %{conn: conn} do
      conn = get(conn, ~p"/about/credits")

      assert html_response(conn, 200) =~ "Glimesh Credits"
    end
  end
end
