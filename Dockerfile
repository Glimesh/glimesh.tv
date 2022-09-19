# Doesn't use alpine because we need dart-sass to work and it needs glibc
FROM elixir:1.14 AS build

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
COPY assets assets
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY priv priv
copy lib lib

# compile and build release
RUN mix compile
RUN mix assets.deploy
RUN mix release

# prepare release image
FROM debian:bullseye-slim AS app
RUN apt-get update
RUN apt-get install -y --no-install-recommends libssl-dev libncurses-dev ca-certificates imagemagick librsvg2-bin npm

RUN npm install -g svgo

WORKDIR /app

RUN chown nobody:nogroup /app

USER nobody:nogroup

COPY --from=build --chown=nobody:nogroup /app/_build/prod/rel/glimesh ./

ENV HOME=/app

CMD ["bin/glimesh", "start"]

# Appended by flyctl
ENV ECTO_IPV6 true
ENV ERL_AFLAGS "-proto_dist inet6_tcp"
