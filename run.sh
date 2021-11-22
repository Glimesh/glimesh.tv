#!/bin/sh

set -e

# install dependencies
mix deps.get

# create and migrate database
mix ecto.setup

# install nodejs stuff
npm --prefix ./assets ci --progress=false --no-audit --loglevel=error
mix assets.deploy

FILE=./priv/cert/selfsigned.pem
if [ ! -f "$FILE" ]; then
    mix phx.gen.cert
fi

# start server
mix phx.server
