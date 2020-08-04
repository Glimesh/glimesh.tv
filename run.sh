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
    
# ==== Uncomment this region before running if you don't have access to the private stylesheets =====
#cd assets

#cd static
#mkdir css
#cd css
#wget https://glimesh.tv/css/app.css
#cd ../../..
# ==== End region ====

# start server
mix phx.server
