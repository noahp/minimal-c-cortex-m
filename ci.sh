#!/usr/bin/env bash

# Simple test script to run the tests in docker

# Error on any non-zero command, and print the commands as they're run
set -ex

# Make sure we have the docker utility
if ! command -v docker; then
    echo "🐋 Please install docker first 🐋"
    exit 1
fi

# Set the docker image name to default to repo basename
DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-$(basename -s .git "$(git remote --verbose | awk 'NR==1 { print tolower($2) }')")}

# build the docker image
DOCKER_BUILDKIT=1 docker build -t "$DOCKER_IMAGE_NAME" --build-arg "UID=$(id -u)" -f Dockerfile .

# permit passing through DISABLE_PRECOMMIT=1 flag to skip that part of ci
docker run \
  --rm \
  --volume "$(pwd)":/mnt/workspace \
  --env=DISABLE_PRECOMMIT="${DISABLE_PRECOMMIT}" \
  --tty \
  "$DOCKER_IMAGE_NAME" \
  bash -c '
    set -ex
    # commit checker
    [ "$DISABLE_PRECOMMIT" != "1" ] && pre-commit run --all-files
    # make commands
    ENABLE_STDIO=0 make
    git clean -dxff
    ENABLE_STDIO=1 make
    git clean -dxff
    ENABLE_STDIO=0 make CC=clang-12
    git clean -dxff
    ENABLE_STDIO=1 make CC=clang-12
    git clean -dxff
    # build everything, clang and gcc
    _devices=$(find devices/ -maxdepth 1 -mindepth 1 -type d | cut -d "/" -f 2)
    echo $_devices | xargs -I % -t -d " " bash -c "
      make clean && ENABLE_STDIO=1 ENABLE_RTT=1 DEVICE=% make -j12 &&
      make clean && ENABLE_STDIO=1 ENABLE_RTT=1 DEVICE=% CC=clang-12 make -j12"
'
