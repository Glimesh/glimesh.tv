# Doesn't use alpine because we need dart-sass to work and it needs glibc
FROM elixir:1.13.1 AS build

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt-get install -y nodejs

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

# workaround for janus npm install
RUN git config --global url."https://github.com".insteadOf ssh://git@github.com

# build assets
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY priv priv
COPY assets assets
RUN mix assets.deploy

# compile and build release
COPY lib lib
# uncomment COPY if rel/ exists
# COPY rel rel
RUN mix do compile, release

# prepare release image
FROM alpine:3.12 AS app
RUN apk add --no-cache openssl gcc libc-dev ncurses-libs imagemagick librsvg npm

RUN npm install -g svgo

WORKDIR /app

RUN chown nobody:nobody /app

USER nobody:nobody

COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/glimesh ./

ENV HOME=/app

RUN ls /app

CMD ["bin/glimesh", "start"]
