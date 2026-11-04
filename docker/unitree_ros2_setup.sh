#!/bin/bash
# Source before talking to the real Go2 (IMU calibration, system_real_robot*.sh, ros2 topic list).
# Pins CycloneDDS to the Ethernet port wired to Go2; override with GO2_IFACE=<iface>.
# GO2_PEERS (set by run.sh / rviz.sh for viewing over Wi-Fi) lists IPs of other ROS machines to
# discover over unicast; both sides need it, since multicast does not cross from Wi-Fi to eth0.
source /opt/ros/foxy/setup.bash
source /opt/cyclonedds_ws/install/setup.bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
DISCOVERY=""
if [ -n "$GO2_PEERS" ]; then
    for p in $GO2_PEERS; do
        DISCOVERY="$DISCOVERY<Peer address=\"$p\" />"
    done
    DISCOVERY="<Discovery><ParticipantIndex>auto</ParticipantIndex><MaxAutoParticipantIndex>50</MaxAutoParticipantIndex><Peers>$DISCOVERY</Peers></Discovery>"
fi
export CYCLONEDDS_URI="<CycloneDDS><Domain><General><Interfaces>
                            <NetworkInterface name=\"${GO2_IFACE:-eno1}\" priority=\"default\" multicast=\"default\" />
                        </Interfaces></General>$DISCOVERY</Domain></CycloneDDS>"
if [ -f ~/autonomy_stack_go2/install/setup.bash ]; then
    source ~/autonomy_stack_go2/install/setup.bash
fi
echo "Unitree ROS2 env ready (CycloneDDS on ${GO2_IFACE:-eno1}${GO2_PEERS:+, peers $GO2_PEERS})"
