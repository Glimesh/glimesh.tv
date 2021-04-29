defmodule Glimesh.Socials.SanitizerTest do
  use Glimesh.DataCase
  alias Glimesh.Socials.Sanitizer

  test "it removes @ from the beginning of a username" do
    assert Sanitizer.sanitize("@username") == "username"
  end

  test "it does not removes @ from the end of a username" do
    assert Sanitizer.sanitize("@username@") == "username@"
  end

  test "it removes multiple @ symbols from beginning of string" do
    assert Sanitizer.sanitize("@@@@@@username") == "username"
  end

  test "it removes whitespace" do
    assert Sanitizer.sanitize("     username     ") == "username"
  end

  test "it removes slashes" do
    assert Sanitizer.sanitize("////username////") == "username"
  end

  test "it removes a guilded url" do
    assert Sanitizer.sanitize("https://guilded.gg/TheKeep", :guilded) == "TheKeep"
  end

  test "it does not break when is nil" do
    assert Sanitizer.sanitize(nil) == nil
  end

  test "it does not break a normal username" do
    assert Sanitizer.sanitize("TheKeep", :guilded) == "TheKeep"
  end

  test "it does not break when guilded is nil" do
    assert Sanitizer.sanitize(nil, :guilded) == nil
  end

  test "it does not break when someone puts the guilded url" do
    assert Sanitizer.sanitize("https://guilded.gg/TheKeep", :guilded) == "TheKeep"
  end
end
