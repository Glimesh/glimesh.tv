defmodule Glimesh.TfaTest do
  use Glimesh.DataCase

  alias Glimesh.Tfa

  describe "generate_secret/1" do
    test "generates a secret under 92 characters" do
      secret = Tfa.generate_secret("test")
      assert String.length(secret) <= 92
    end

    test "tfa works" do
      secret = Tfa.generate_secret("test")
      pin = Tfa.generate_totp(secret)
      assert Glimesh.Tfa.validate_pin(pin, secret)
    end
  end

  describe "generate_tfa_img/4" do
    test "generates a working image" do
      tfa_image =
        Tfa.generate_tfa_img("Glimesh", "dIpBbOuRvDQICSNXNSjpmcBP", Tfa.generate_secret("test"))

      assert validate(tfa_image) == true
    end
  end

  defp validate(image_data) do
    case get_file_type(image_data) do
      {:ok, type} ->
        type in [:png]

      _ ->
        false
    end
  end

  defp get_file_type(image_data) when is_binary(image_data) do
    case image_data do
      <<137, 80, 78, 71, 13, 10, 26, 10, _rest::binary>> ->
        {:ok, :png}

      _ ->
        {:ok, :unknown}
    end
  end
end
