# Glimesh.tv
![Elixir CI](https://github.com/glimesh/glimesh.tv/workflows/Elixir%20CI/badge.svg)

## Installation

To install a local copy of Glimesh.tv, run `git clone --recursive git@github.com:Glimesh/glimesh.tv.git`. This will clone the repository, as well as the css submodule if you have access to it.

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `npm install` inside the `assets` directory
  * Generate local SSL certificates with `mix phx.gen.cert`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

### Docker
Glimesh.tv can also be set up for **development use only** using [docker-compose](https://docs.docker.com/compose/install/).

To do so, run the following commands from the GitHub repository:

1. `touch .env`
2. `docker-compose -f docker-compose.yml -f docker-compose.dev.yml up`

### Customizing your local environment
You can create a `config/local.exs` config file to change any local settings to make development 
easier. This file is ignored from git, so you don't have to worry about committing any secrets.

```elixir
use Mix.Config

config :glimesh, GlimeshWeb.Endpoint,
  url: [host: "glimesh.dev", port: 443]
```

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
