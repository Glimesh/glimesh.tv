defmodule Glimesh.Tfa do

  @doc """
  This generates the 2FA image for a totp Authenticatior such as Google Authenticator or Authy
  """
  def generate_tfa_img(issuer, accountTitle, secret) do
    accountTitleNoSpaces = String.replace(accountTitle, " ", "")
    provisionUrl = "otpauth://totp/#{accountTitleNoSpaces}?secret=#{secret}&issuer=#{issuer}"
    provisionUrl
    |> EQRCode.encode()
    |> EQRCode.svg(width: 355, background_color: :transparent, color: "#1b55e2")
  end

  defp generate_hmac(secret, period) do
    moving_factor = DateTime.utc_now()
      |> DateTime.to_unix()
      |> Integer.floor_div(period)
      |> Integer.to_string(16)
      |> String.pad_leading(16, "0")
      |> String.upcase()
      |> Base.decode16!()
    secretBytes = Base.decode32!(secret, padding: false)
    :crypto.hmac(:sha, secretBytes, moving_factor)
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
  def generate_totp(secret, period \\ 30) do
    secret
      |> generate_hmac(period)
      |> hmac_dynamic_truncation
      |> generate_hotp
  end

  @doc """
  Validates the pin with the secret key supplied
  """
  def validate_pin(pin, secret) do
    serverPin = generate_totp(secret)
    cond do
      pin == serverPin -> secret
      pin != serverPin -> nil
    end
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
