defmodule Glimesh.Credits do
  @moduledoc """
  Provides mechanisms for generating the credits page.
  """

  @doc """
  In the future, get_dependencies should quickly load the deps from a cache.
  """
  def get_dependencies do
    compile_dependencies()
  end

  @doc """
  In the future, compile_dependencies will cache these on app startup so we don't have to load them every time.
  """
  def compile_dependencies do
    %{
      ftl: ftl_deps(),
      node: node_deps(),
      elixir: elixir_deps()
    }
  end

  defp ftl_deps do
    [
      {"janus-gateway", "General purpose WebRTC server designed and developed by Meetecho."},
      {"glib-2.0",
       "GLib provides the core application building blocks for libraries and applications written in C."},
      {"libsrtp2",
       "Implementation of the Secure Real-time Transport Protocol (SRTP), the Universal Security Transform (UST), and a supporting cryptographic kernel. "},
      {"jansson", "Jansson is a C library for encoding, decoding and manipulating JSON data."},
      {"libssl",
       "OpenSSL is a robust, commercial-grade, and full-featured toolkit for the Transport Layer Security (TLS) and Secure Sockets Layer (SSL) protocols."},
      {"libcrypto", "General-purpose cryptography library"},
      {"libavcodec",
       "Generic encoding/decoding framework and contains multiple decoders and encoders for audio, video and subtitle streams, and several bitstream filters."},
      {"spdlog", "Very fast, header-only/compiled, C++ logging library."}
    ]
  end

  defp node_deps do
    case File.read("assets/package.json") do
      {:ok, content} ->
        Jason.decode!(content) |> Map.get("dependencies", [])

      {:error, _} ->
        []
    end
  end

  defp elixir_deps do
    Application.loaded_applications()
  end
end
