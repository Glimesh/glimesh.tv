#!/bin/sh

set -e

# install dependencies
mix deps.get

# create and migrate database
mix ecto.setup

# install nodejs stuff
cd assets && npm ci
cd ..

FILE=./priv/cert/selfsigned.pem
if [ ! -f "$FILE" ]; then
    mix phx.gen.cert
fi

# start server
mix phx.server
