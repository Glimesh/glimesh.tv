defmodule Glimesh.Tfa do
  @moduledoc """
  Two factor auth helper functionality.
  """

  @doc """
  This generates the 2FA image for a totp Authenticatior such as Google Authenticator or Authy
  """
  def generate_tfa_img(issuer, account_title, secret, color \\ "normal") do
    account_title_no_spaces = String.replace(account_title, " ", "")
    provision_url = "otpauth://totp/#{account_title_no_spaces}?secret=#{secret}&issuer=#{issuer}"

    provision_url
    |> EQRCode.encode()
    |> output_png(color)
  end

  defp output_png(input, "normal") do
    EQRCode.png(input, width: 355, background_color: :transparent, color: <<27, 85, 226>>)
  end

  defp output_png(input, "bw") do
    EQRCode.png(input, width: 355, background_color: <<255, 255, 255>>, color: <<0, 0, 0>>)
  end

  defp generate_hmac(secret, period, seconds_offset \\ 0) do
    moving_factor =
      DateTime.utc_now()
      |> DateTime.add(seconds_offset)
      |> DateTime.to_unix()
      |> Integer.floor_div(period)
      |> Integer.to_string(16)
      |> String.pad_leading(16, "0")
      |> String.upcase()
      |> Base.decode16!()

    secret_bytes = Base.decode32!(secret, padding: false)
    :crypto.hmac(:sha, secret_bytes, moving_factor)
  end

  defp hmac_dynamic_truncation(hmac) do
    # Get the offset from last  4-bits
    <<_::19-binary, _::4, offset::4>> = hmac
    # Get the 4-bytes starting from the offset
    <<_::size(offset)-binary, p::4-binary, _::binary>> = hmac
    # Return the last 31-bits
    <<_::1, truncation::31>> = p
    truncation
  end

  defp generate_hotp(truncated_hmac) do
    truncated_hmac
    |> rem(1_000_000)
    |> Integer.to_string()
  end

  @doc """
  Generate Time-Based One-Time Password.
  The default period used to calculate the moving factor is 30s
  """
  def generate_totp(secret, steps_ago \\ 0, period \\ 30) do
    secret
    |> generate_hmac(period, steps_ago * period * -1)
    |> hmac_dynamic_truncation
    |> generate_hotp
  end

  @doc """
  Validates the pin with the secret key supplied
  """
  def validate_pin(pin, secret, steps \\ 1)

  def validate_pin(_pin, secret, _steps) when is_nil(secret) do
    true
  end

  def validate_pin(pin, secret, steps) do
    0..steps
    |> Enum.any?(&(pin == generate_totp(secret, &1)))
  end

  @doc """
  Generates a pseudo random secret key based on a string input
  """
  def generate_secret(key) do
    key
    |> Bcrypt.hash_pwd_salt()
    |> Base.encode32(padding: false)
  end
end
