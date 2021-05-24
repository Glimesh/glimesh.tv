# Glimesh.tv
![Elixir CI](https://github.com/glimesh/glimesh.tv/workflows/Elixir%20CI/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/Glimesh/glimesh.tv/badge.svg?branch=dev)](https://coveralls.io/github/Glimesh/glimesh.tv?branch=dev)

Glimesh is a next generation streaming platform built by the community, for the community.
Our platform focuses on increasing discoverability for content creators and implementing the
latest in streaming technology to level the playing field. We understand the importance of
interaction between content creators and their fans and we’re dedicated to innovating new
ways to bring communities closer together.

This repository houses the Glimesh.tv back-end and browser front-end.

## Table of Contents
* [Development Installation](#development-installation)
  + [General Dependencies](#general-dependencies)
  + [Cloning](#cloning)
  + [Windows Installation](#windows-installation)
  + [Ubuntu Installation (including WSL2 + Ubuntu)](#ubuntu-installation--including-wsl2---ubuntu-)
    - [Configuring Postgres](#configuring-postgres)
  + [macOS Installation](#macos-installation)
  + [Preparing to run](#preparing-to-run)
  + [Run!](#run-)
    - [SSL/HTTPS](#ssl-https)
  + [Docker](#docker)
  + [Customizing your local environment](#customizing-your-local-environment)
* [Developing](#developing)
  + [Modifying Code](#modifying-code)
  + [Running Static Code Analysis](#running-static-code-analysis)
  + [Contributing](#contributing)
* [Testing](#testing)
* [Help](#help)
* [Security Policy](#security-policy)
* [License](#license)

## Development Installation

These instructions serve as a reference for getting Glimesh running whatever type of local machine you have for development. Some instructions may be specific to various distributions, substitution may be required with the correct procedure for your configuration.

### General Dependencies

You will need the following tools to clone, build, and run Glimesh:

- **git**: Source control
- **erlang**: Runtime
- **elixir**: Language and tooling
- **postgresql**: Database
- **nodejs / npm**: Front-end package management
- **inotify-tools**: Filesystem monitoring dependencies for developer convenience (watching changes)

You will need these optional dependencies for advanced functionality:
- **rsvg-convert**: SVG to PNG conversion for emotes
- **svgo** - SVG Optimization for emotes

You may need to translate these exact dependencies into their appropriate names for your OS distribution.

### Cloning

To clone a local copy of Glimesh.tv, run

```sh
git clone https://github.com/Glimesh/glimesh.tv.git
# or if you have permissions to the repository, or prefer to use SSH authentication
# git clone git@github.com:Glimesh/glimesh.tv.git
```

**NOTE**: If you are using WSL2, ensure you are cloning inside of your WSL2 instance
(ex. `/home/user/...`) and not inside of a mounted Windows drive (ex. `/mnt/c/Users/...`)
as this can have a significant negative impact on performance.

### Windows Installation

Running Glimesh.tv natively on Windows is not yet understood. However you can run the application very well with WSL2. If you are interested in running Glimesh.tv natively, have a go at us and let us know!

[WSL2](https://docs.microsoft.com/en-us/windows/wsl/install-win10) with Ubuntu 18.04 & 20.04 has been tested successfully for development on Windows.

### Ubuntu Installation (including WSL2 + Ubuntu)
On modern versions of Ubuntu, you can install these packages with the following command:

```sh
sudo apt install git esl-erlang elixir postgresql npm inotify-tools
```

#### Configuring Postgres

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


### macOS Installation

Installation is simple with [Homebrew](https://brew.sh).

```sh
# Required dependencies
brew install elixir imagemagick node
# Graphical Postgres, if you do not want a graphical Postgres, you are on your own!
brew install --cask postgres
```

After you've completed these install steps, launch the Postgres.app and Initialize the server. You are ready to run Glimesh.tv at this point.

### Preparing to run

`cd` into the directory where you cloned Glimesh.tv and run the following to pull Elixir
dependencies:

```sh
mix deps.get
```

Then, run the following to set up the database:

```sh
mix ecto.setup
```

Then, pull the front-end dependencies from the assets directory.

```sh
npm ci --prefix=assets
```

Then, run the following to generate local SSL certificates (for HTTPS)

```sh
mix phx.gen.cert
```

### Run!

Finally, you can run the following command to start the Glimesh.tv service:

```sh
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

#### SSL/HTTPS

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

### Docker
Glimesh.tv can also be set up for **development use only** using [docker-compose](https://docs.docker.com/compose/install/).

To do so, run the following commands from the GitHub repository:

`docker-compose up`

Then you can visit the site at: `http://localhost:4000`

To run tests you can start a docker instance and run tests on them by doing the following

```bash
docker-compose run app bash
app> mix test
```

### Customizing your local environment
You can create a `config/local.exs` config file to change any local settings to make development
easier. This file is ignored from git, so you don't have to worry about committing any secrets.

```elixir
use Mix.Config

config :glimesh, GlimeshWeb.Endpoint,
  url: [host: "glimesh.dev", port: 443]
```

## Developing

Most of the core code behind the project is located is clear directories, grouped with other similar code. Here are a couple of the directories you'll frequently be working with:

| Directory                           | Frontend | Backend | Description                                                                                                                            |
|-------------------------------------|----------|---------|----------------------------------------------------------------------------------------------------------------------------------------|
| assets/css                          | ✅        |         | SCSS directory for all of our styles, using Bootstrap 4.5                                                                              |
| assets/js                           | ✅        |         | Our simple JavaScript hooks. Generally triggered directly from a LiveView based on an action. We strive to keep the JavaScript minimal |
| lib/glimesh_web/{live, templates}   | ✅        |         | Phoenix LiveView's and regular controller based views (called templates in Phoenix)                                                    |
| lib/glimesh                         |          | ✅       | Core Elixir domain logic & DB interactions                                                                                             |
| lib/glimesh_web/{live, controllers} |          | ✅       | Phoenix LiveView's and regular controllers                                                                                             |
| priv/repo/migrations                |          | ✅       | Ecto migrations for the Postgres database                                                                                              |
| test                                | ✅        | ✅       | All testing, both functional and integrated using ExUnit                                                                               |
| config                              |          |  ✅      | Configuration for local, testing, and production releases                                                                              |

### Modifying Code
All code inside any known directory is automatically watched for changes and triggers the appropriate build. Some frontend code and live views will automatically refresh your browser, but for more complex domain logic you may be required to refresh your browser.

### Running Static Code Analysis
Before submitting a pull request, be sure to run [Credo](https://github.com/rrrene/credo) which will run a static code analysis over the entire project.
```sh
mix code_quality
```

### Contributing
1. [Fork it!](http://github.com/Glimesh/glimesh.tv/fork)
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create new Pull Request


## Testing
Glimesh includes a comprehensive and very fast test suite, so you should be encouraged to run tests as frequently as possible.

```sh
mix test
```

Any broken tests will be called out with the file and line number. If you are working on a single test, or a single test file you can easily specify a smaller test sample with:

```sh
mix test test/glimesh/your_test.exs
# Or specifying a specific line
mix test test/glimesh/your_test.exs:15
```

## Help
If you need help with anything, please feel free to open [a GitHub Issue](https://github.com/Glimesh/glimesh.tv/issues/new).

## Security Policy
Our security policy can be found in [SECURITY.md](SECURITY.md).

## License
Glimesh.tv is licensed under the [MIT License](LICENSE.md).
