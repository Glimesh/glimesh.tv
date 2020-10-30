# Glimesh.tv
![Elixir CI](https://github.com/glimesh/glimesh.tv/workflows/Elixir%20CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/Glimesh/glimesh.tv/badge.svg?branch=master)](https://coveralls.io/github/Glimesh/glimesh.tv?branch=master)

Glimesh is a next generation streaming platform built by the community, for the community.
Our platform focuses on increasing discoverability for content creators and implementing the
latest in streaming technology to level the playing field. We understand the importance of
interaction between content creators and their fans and we’re dedicated to innovating new
ways to bring communities closer together.

This repository houses the Glimesh.tv back-end and browser front-end.

# Development Installation

These instructions serve as a reference for getting Glimesh running on a Linux machine for local development. Some instructions may be specific to Ubuntu distributions, substitute with for the correct procedure for your configuration where appropriate.

[WSL2](https://docs.microsoft.com/en-us/windows/wsl/install-win10) with Ubuntu 20.04 has been tested successfully for development on Windows.

## Dependencies

You will need the following tools to clone, build, and run Glimesh: 

- **git**: Source control
- **erlang**: Runtime
- **elixir**: Language and tooling
- **postgresql**: Database
- **nodejs / npm**: Front-end package management
- **inotify-tools**: Filesystem monitoring dependencies for developer convenience (watching changes)

On modern versions of Ubuntu, you can install these packages with the following command:

```sh
sudo apt install git esl-erlang elixir postgresql npm inotify-tools
```

Other distributions likely have packages available for these tools as well.

## Cloning

To clone a local copy of Glimesh.tv, run

```sh
git clone --recursive git@github.com:Glimesh/glimesh.tv.git
```

This will clone the repository, as well as the css submodule if you have access to it.

**NOTE**: If you are using WSL2, ensure you are cloning inside of your WSL2 instance
(ex. `/home/user/...`) and not inside of a mounted Windows drive (ex. `/mnt/c/Users/...`)
as this can have a significant negative impact on performance.

## Configuring Postgres

After installing the postgresql package, you may need to fire up the postgresql server:

```sh
sudo pg_ctlcluster 12 main start
```

You will then need to add a password for the default `postgres` user so that the Glimesh service can access the database. The password Glimesh is configured to use by default in a dev environment is `postgres`. Postgres by default will only allow connections from localhost - for a development environment this is generally acceptable. If you are more concerned about securing your Postgres
instance, consider using a different password.

Run the following command to enter a postgres prompt:

```sh
sudo -u postgres psql
```

When presented with the `postgres=#` prompt, you can run `\password postgres` to change the password
for the postgres user. Enter `postgres` as the password, enter it again to confirm, then enter
`\quit` to exit the postgres prompt.

```
postgres=# \password postgres
Enter new password:
Enter it again:
\quit
```

## Preparing to run

`cd` into the directory where you cloned Glimesh.tv and run the following to pull Elixir
dependencies:

```sh
mix deps.get
```

Then, run the following to set up the database:

```sh
mix ecto.setup
```

Then, `cd` into the assets directory and run `npm install` to pull front-end dependencies.

```sh
pushd assets
npm install
popd
```

Then, run the following to generate local SSL certificates (for HTTPS)

```sh
mix phx.gen.cert
```

## Run!

Finally, you can run the following command to start the Glimesh.tv service:

```sh
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### SSL/HTTPS

**Note**: In order to connect with HTTPS, you will need to add the generated self-signed
certificate to your trusted store.

To do this on Windows, find the `priv/cert/selfsigned.pem` file that was generated earlier.
In WSL2, you can navigate to your WSL2 machine via `\\wsl$` in Windows Explorer.

Copy the selfsigned.pem file to your Windows machine and change the file extension from
`.pem` to `.crt`.

Double click the `.crt` file and select "Install Certificate...".

Choose "Current User" for Store Location and press "Next".

Select "Place all certificates in the following store" and press the "Browse..." button.

Select "Trusted Root Certification Authorities" and press "OK".

Press "Next" and finish the Certificate Import Wizard. When prompted to trust the certificate,
press "Okay".

Now you can visit your local Glimesh dev instance via HTTPS at [`localhost:4001`](https://localhost:4001)!

## Docker
Glimesh.tv can also be set up for **development use only** using [docker-compose](https://docs.docker.com/compose/install/).

To do so, run the following commands from the GitHub repository:

1. `touch .env`
2. `docker-compose -f docker-compose.yml -f docker-compose.dev.yml up`

## Customizing your local environment
You can create a `config/local.exs` config file to change any local settings to make development 
easier. This file is ignored from git, so you don't have to worry about committing any secrets.

```elixir
use Mix.Config

config :glimesh, GlimeshWeb.Endpoint,
  url: [host: "glimesh.dev", port: 443]
```