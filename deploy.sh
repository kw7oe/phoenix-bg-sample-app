#!/bin/bash
set -e

# Getting your app name from mix.exs
APP_NAME="$(grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g')"
APP_VSN="$(grep 'version:' mix.exs | cut -d '"' -f2)"
TAR_FILENAME=${APP_NAME}-${APP_VSN}.tar.gz

bold_echo() {
  echo -e "\033[1m---> $1\033[0m"
}

build_release() {
  bold_echo "Building Docker images..."
  docker build -t life_app .

  bold_echo "Extracting release tar file..."
  ID=$(docker create life_app)
  docker cp "$ID:/app/$TAR_FILENAME" .
  docker rm "$ID"
}

if [ "$1" = "build" ]; then
  build_release
fi


