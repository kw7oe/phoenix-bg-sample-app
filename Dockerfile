FROM hexpm/elixir:1.11.3-erlang-23.2.5-ubuntu-focal-20210119 AS build

# ===========
# Application
# ===========

# install build dependencies
# RUN apk add --no-cache build-base npm
RUN apt-get update && \
  apt-get install -y build-essential curl gnupg2 && \
  curl -sL https://deb.nodesource.com/setup_12.x | bash - && \
  apt-get install -y nodejs && node -v && npm -v

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

# build assets
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm --prefix ./assets ci --progress=false --no-audit --loglevel=error

COPY priv priv
COPY assets assets
RUN npm run --prefix ./assets deploy
RUN mix phx.digest

# compile and build release
COPY lib lib
# uncomment COPY if rel/ exists
# COPY rel rel
RUN mix do compile, release

# ==================
# To extract release
# ==================
FROM scratch AS app
WORKDIR /app
COPY --from=build /app/_build/prod/sample-*.tar.gz ./
CMD ["/bin/bash"]



