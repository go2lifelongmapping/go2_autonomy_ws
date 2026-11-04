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

# Logged in over SSH from a laptop on Wi-Fi: let RViz2 on that laptop reach this machine (rviz.sh)
EXEC_ENV=""
CLIENT_IP=${SSH_CLIENT%% *}
case "$CLIENT_IP" in
    ""|192.168.123.*) ;;
    *)
        EXEC_ENV="-e GO2_PEERS=$CLIENT_IP"
        echo "SSH qua WiFi từ $CLIENT_IP: RViz2 trên máy đó sẽ xem được qua WiFi"
        ;;
esac

$COMPOSE up -d
$COMPOSE exec $EXEC_ENV go2 bash
