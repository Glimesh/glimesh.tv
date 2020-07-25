#!/bin/sh

set -e

# install dependencies
mix deps.get

# create and migrate database
mix ecto.setup

# install nodejs stuff then go back to root
#cd assets && npm install
#cd ..

#mix phx.gen.cert

#cd assets

#cd static
#mkdir css
#cd css
#wget https://glimesh.tv/css/app.css

# start server
mix phx.server
