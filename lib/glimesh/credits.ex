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
      {"libavcodec",
       "Library from ffmpeg providing a encoding/decoding framework and multiple decoders and encoders for audio, video and subtitle streams, and several bitstream filters."},
      {"spdlog", "Very fast, header-only/compiled, C++ logging library."},
      {"cpp-httplib", "A C++11 single-file header-only cross platform HTTP/HTTPS library."},
      {"Catch2",
       "A modern, C++-native, header-only, test framework for unit-tests, TDD and BDD - using C++11 or later."}
    ]
  end

  defp node_deps do
    [
      {"@fortawesome/fontawesome-free", "The iconic font, CSS, and SVG framework."},
      {"@github/markdown-toolbar-element", "Markdown formatting buttons for text inputs."},
      {"@github/time-elements",
       "Formats a timestamp as a localized string or as relative text that auto-updates in the user's browser."},
      {"@joeattardi/emoji-button", "Vanilla JavaScript emoji picker."},
      {"@yaireo/tagify",
       "Lightweight, efficient Tags input component in Vanilla JS / React / Angular [super customizable, tiny size & top performance]."},
      {"apexcharts", "A JavaScript Chart Library."},
      {"bootstrap",
       "The most popular front-end framework for developing responsive, mobile first projects on the web."},
      {"bootstrap.native",
       "Native JavaScript for Bootstrap, the sweetest JavaScript library without jQuery."},
      {"bs-custom-file-input",
       "A little plugin which makes Bootstrap 4 custom file input dynamic with no dependencies."},
      {"choices.js", "A vanilla JS customisable text input/select box plugin."},
      {"janus-ftl-player", "Simple player for Janus FTL streams."}
    ]
  end

  defp elixir_deps do
    Application.loaded_applications()
  end
end
