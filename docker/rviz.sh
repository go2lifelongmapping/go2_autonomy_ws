#!/bin/bash
# Open RViz2 on this PC for the Go2 stack running on the robot's Jetson.
#   docker/rviz.sh          Waypoint mode   (Jetson runs ./system_real_robot.sh)
#   docker/rviz.sh route    Goalpoint mode  (Jetson runs ./system_real_robot_with_route_planner.sh)
# Uses the Ethernet cable when plugged in, otherwise Wi-Fi. Over Wi-Fi the Jetson stack must be
# started from an SSH session coming from this PC over Wi-Fi (run.sh then sets GO2_PEERS there).
set -e
if [ "$(uname -m)" = "aarch64" ]; then
    echo "Đây là Jetson của Go2 (không có màn hình). Chạy rviz.sh trên PC, trong terminal KHÔNG ssh." >&2
    exit 1
fi
JETSON=192.168.123.18
LAN=${GO2_IFACE:-eno1}
WIFI=${GO2_WIFI_IFACE:-wlp3s0}
if [ "$(cat /sys/class/net/$LAN/carrier 2>/dev/null)" = "1" ]; then
    IFACE=$LAN
    PEERS=""
    echo "Dùng dây mạng ($LAN)"
else
    # The Jetson's DDS only uses eth0, so reach its 192.168.123.18 through its Wi-Fi address
    on_wifi() { [ -n "$1" ] && ip route get "$1" 2>/dev/null | grep -qE "^$1 dev $WIFI "; }
    CACHE=~/.cache/go2_jetson_wifi
    JETSON_WIFI=$GO2_JETSON_WIFI
    if [ -z "$JETSON_WIFI" ]; then
        # mDNS may answer with the Jetson's cable address, so only accept one on the Wi-Fi subnet
        JETSON_WIFI=$(timeout 5 avahi-resolve-host-name -4 ubuntu.local 2>/dev/null | awk '{print $2}')
        on_wifi "$JETSON_WIFI" || JETSON_WIFI=""
    fi
    if [ -z "$JETSON_WIFI" ] && [ -f $CACHE ]; then
        JETSON_WIFI=$(cat $CACHE)
        on_wifi "$JETSON_WIFI" && ping -c 1 -W 2 "$JETSON_WIFI" >/dev/null 2>&1 || JETSON_WIFI=""
    fi
    if [ -n "$JETSON_WIFI" ]; then
        mkdir -p ~/.cache && echo "$JETSON_WIFI" > $CACHE
    else
        echo "Không có dây mạng và không tìm thấy Jetson (ubuntu.local) trên WiFi." >&2
        echo "Kiểm tra Jetson cùng mạng WiFi, hoặc chạy: GO2_JETSON_WIFI=<IP WiFi Jetson> $0 $*" >&2
        exit 1
    fi
    if ! ip route get $JETSON | grep -q "via $JETSON_WIFI dev $WIFI"; then
        # runtime only: gone when Wi-Fi reconnects
        nmcli device modify $WIFI ipv4.routes "$JETSON/32 $JETSON_WIFI" >/dev/null
        sleep 1
    fi
    IFACE=$WIFI
    PEERS=$JETSON
    echo "Dùng WiFi ($WIFI, Jetson $JETSON_WIFI). Hệ thống trên Jetson phải được chạy từ SSH qua WiFi:"
    echo "    ssh unitree@$JETSON_WIFI  ->  ./docker/run.sh  ->  source /opt/unitree_ros2_setup.sh  ->  ./system_real_robot.sh"
fi

CONFIG='$(ros2 pkg prefix vehicle_simulator)/share/vehicle_simulator/rviz/vehicle_simulator.rviz'
if [ "$1" = "route" ]; then
    CONFIG='$(ros2 pkg prefix far_planner)/share/far_planner/rviz/default.rviz'
fi

cd "$(dirname "$0")"
mkdir -p ../calib ../bags
export HOST_UID=$(id -u) HOST_GID=$(id -g)
export VIDEO_GID=$(getent group video | cut -d: -f3)
export RENDER_GID=$(getent group render | cut -d: -f3)

docker compose up -d
docker compose exec -e GO2_IFACE=$IFACE -e GO2_PEERS=$PEERS go2 bash -ic \
    "source /opt/unitree_ros2_setup.sh && rviz2 -d $CONFIG"
