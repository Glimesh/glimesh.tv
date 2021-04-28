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
end
