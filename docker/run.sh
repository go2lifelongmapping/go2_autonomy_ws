#!/bin/bash
# Start the Foxy container (building the image on first run) and open a shell in it.
set -e
cd "$(dirname "$0")"
mkdir -p ../calib ../bags

export HOST_UID=$(id -u) HOST_GID=$(id -g)
export VIDEO_GID=$(getent group video | cut -d: -f3)
export RENDER_GID=$(getent group render | cut -d: -f3)

COMPOSE="docker compose"
if [ "$(uname -m)" = "aarch64" ]; then
    COMPOSE="docker compose -f docker-compose.yml -f docker-compose.jetson.yml"
fi

$COMPOSE up -d
$COMPOSE exec go2 bash
