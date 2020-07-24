use Mix.Config
config :glimesh, GlimeshWeb.Endpoint,
       url: [host: "glimesh.dev", port: 443],
       https: [
         port: 443,
         cipher_suite: :strong,
         keyfile: "~/Code/Secure/glimesh.dev.key",
         certfile: "~/Code/Secure/glimesh.dev",
         transport_options: [socket_opts: [:inet6]]
       ]

config :stripity_stripe, api_key: "sk_test_51H879QBLNaYgaiU5CBQUoUms4qiz5NFjngShoCEjEnMlxpbCpl2b3U6vBtLowgQE1drjm3NiYC8ZUJYNbEUyKGQ900jSAidDHT"