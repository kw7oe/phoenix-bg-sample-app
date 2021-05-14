#!/bin/bash
set -e

# Getting your app name from mix.exs
# I probably copy the code from somewhere so...
APP_NAME="$(grep 'app:' mix.exs | sed -e 's/\[//g' -e 's/ //g' -e 's/app://' -e 's/[:,]//g')"
APP_VSN="$(grep 'version:' mix.exs | cut -d '"' -f2)"
TAR_FILENAME=${APP_NAME}-${APP_VSN}.tar.gz

# I'm using vagrant to test out the application.
# So change this to your own host.
HOST="vagrant@192.168.33.40"

# The domain name to curl the blue/green version of your
# service.
DOMAIN="domain.app"

LIVE_VERSION=$(curl -s -w "\n" "$DOMAIN/deployment_id")

bold_echo() {
  echo -e "\033[1m---> $1\033[0m"
}

build_release() {
  bold_echo "Building Docker images..."
  docker build -t $APP_NAME .

  bold_echo "Extracting release tar file..."
  ID=$(docker create $APP_NAME)
  docker cp "$ID:/app/$TAR_FILENAME" .
  docker rm "$ID"
}

deploy_release() {
  bold_echo "Creating directory if not exist..."
  ssh $HOST mkdir -p "$APP_NAME/$APP_VSN"

  bold_echo "Copying environment variables..."

  # I'm storing my production environment variable in my local machine
  # and scp it over to the host every time.
  # Not the recommended way to manage your sercret.
  scp .env.production $HOST:"~/$APP_NAME/.env"

  bold_echo "Copying release to remote..."
  scp "$TAR_FILENAME" $HOST:"~/$APP_NAME/$TAR_FILENAME"
  ssh $HOST tar -xzf "$APP_NAME/$TAR_FILENAME" -C "$APP_NAME/$APP_VSN"

  start_release

  bold_echo "Removing remote tar file..."
  ssh $HOST rm "~/$APP_NAME/$TAR_FILENAME"
}

start_release() {
  LIVE_VERSION=$(curl -s -w "\n" "$DOMAIN/deployment_id")

  if [ "$LIVE_VERSION" = "blue" ]; then
    version_file="green_version.txt"
    deploy_version="green"

    # Since we need to check if our process is running with pid command
    env="RELEASE_NODE=green"
  else
    version_file="blue_version.txt"
    deploy_version="blue"
    env=""
  fi

  # Check if the file exist.
  # If it doesn't exist, it means that we haven't deploy
  # the initial version yet.
  # Hence, we can skip the stopping phase entirely.
  if [ -f $version_file ]; then
    version=$(cat $version_file)

    # Don't exit on error so we can caputure
    set +e
    ssh $HOST "$env ~/$APP_NAME/$version/bin/$APP_NAME pid"

    if [ $? -ne 0 ]; then
      bold_echo "$APP_NAME $version is not running anymore..."
    else
      bold_echo  "Stopping previous $deploy_version, release $version..."
      ssh $HOST "$env ~/$APP_NAME/$version/bin/$APP_NAME stop"

      bold_echo  "Waiting $deploy_version, release $version to stop..."
      ssh $HOST "$env ~/$APP_NAME/$version/bin/$APP_NAME pid"
      while [ $? -ne 1 ]
      do
        bold_echo  "Waiting $deploy_version, release $version to stop..."
        ssh $HOST "$env ~/$APP_NAME/$version/bin/$APP_NAME pid"
      done
    fi
    set -e
  fi

  # Start Release
  if [ "$deploy_version" = "blue" ]; then
    ssh $HOST "source ~/$APP_NAME/.env && PORT=4000 ~/$APP_NAME/$APP_VSN/bin/$APP_NAME daemon"
  else
    ssh $HOST "source ~/$APP_NAME/.env && PORT=5000 ELIXIR_ERL_OPTIONS='-sname green' ~/$APP_NAME/$APP_VSN/bin/$APP_NAME daemon"
  fi

  # Update our version in our version file.
  # So that next time, we know this is the version we are currently
  # running
  echo $APP_VSN > $version_file
}

promote() {
  LIVE_VERSION=$(curl -s -w "\n" "$DOMAIN/deployment_id")

  bold_echo "Attempting to promote to $1..."
  if [ "$LIVE_VERSION" = "$1" ]; then
    echo "$1 is already the live version!"
    return
  elif [ "$1" = "green" ]; then
    target_nginx_file="green"
  else
    target_nginx_file="blue"
  fi

  ssh $HOST "sudo ln -sf /etc/nginx/sites-available/$target_nginx_file /etc/nginx/sites-enabled/$DOMAIN && sudo systemctl reload nginx"

  LIVE_VERSION=$(curl -s -w "\n" "$DOMAIN/deployment_id")
  bold_echo "Promoted live to $LIVE_VERSION"
}

clean_up() {
  bold_echo "Removing local tar file..."
  rm "$APP_NAME-"*.tar.gz
}

migrate() {
  if [ -z "$1" ]; then
    bold_echo "Setting blue green version to $LIVE_VERSION since none specified."
    blue_green_version=$LIVE_VERSION
  else
    bold_echo "Setting blue green version to $1"
    blue_green_version=$1
  fi

  version=$(cat $blue_green_version)
  bold_echo "Running migration for database for release $version..."

  if [ "$blue_green_version" = "blue" ]; then
    env="source ~/$APP_NAME/.env && PORT=4000 "
  else
    env="source ~/$APP_NAME/.env && RELEASE_NODE=green PORT=5000 "
  fi

  ssh $HOST "$env ~/$APP_NAME/$version/bin/$APP_NAME eval 'MyApp.Release.migrate()'"
}


if [ "$1" = "build" ]; then
  build_release
elif [ "$1" = "start" ]; then
  start_release
elif [ "$1" = "promote" ]; then
  promote "$2"
elif [ "$1" = "migrate" ]; then
  migrate "$2"
else
  build_release
  deploy_release
  clean_up
fi

