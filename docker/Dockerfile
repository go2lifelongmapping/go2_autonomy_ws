# ROS2 Foxy (Ubuntu 20.04) environment for autonomy_stack_go2
# osrf/ros:foxy-desktop is amd64 only; the Go2 onboard Jetson (arm64) builds from ros:foxy-ros-base-focal
ARG BASE_IMAGE=osrf/ros:foxy-desktop
FROM ${BASE_IMAGE}

ARG USERNAME=go2
ARG USER_UID=1000
ARG USER_GID=1000
ARG RENDER_GID=110

ENV DEBIAN_FRONTEND=noninteractive

# Dependencies from the repo README (external-computer list) plus runtime extras:
# ros-foxy-desktop (already in the osrf image, needed on the arm64 base), cv_bridge for the camera nodes,
# gstreamer for go2_h264_repub, matplotlib for visualization_tools, mesa for RViz/Unity
RUN apt-get update && apt-get install -y --no-install-recommends \
        ros-foxy-desktop \
        ros-foxy-cv-bridge \
        ros-foxy-image-transport \
        libusb-dev \
        ros-foxy-perception-pcl \
        ros-foxy-sensor-msgs-py \
        ros-foxy-tf-transformations \
        ros-foxy-joy \
        ros-foxy-rmw-cyclonedds-cpp \
        ros-foxy-rosidl-generator-dds-idl \
        python3-colcon-common-extensions \
        python-is-python3 \
        python3-pip \
        python3-matplotlib \
        gstreamer1.0-plugins-good \
        gstreamer1.0-plugins-bad \
        gstreamer1.0-libav \
        libgl1-mesa-dri \
        mesa-utils \
        libvulkan1 \
        mesa-vulkan-drivers \
        git \
        sudo \
        iproute2 \
        iputils-ping \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir transforms3d pyyaml

# Go2 speaks CycloneDDS 0.10.x; Foxy ships 0.7.x, so build 0.10.x + rmw_cyclonedds (foxy)
# the way the Unitree ROS2 guide does: cyclonedds first without ROS sourced, then the rest.
WORKDIR /opt/cyclonedds_ws
RUN git clone --depth 1 -b foxy https://github.com/ros2/rmw_cyclonedds src/rmw_cyclonedds \
    && git clone --depth 1 -b releases/0.10.x https://github.com/eclipse-cyclonedds/cyclonedds src/cyclonedds \
    && colcon build --packages-select cyclonedds --cmake-args -DCMAKE_BUILD_TYPE=Release \
    && . /opt/ros/foxy/setup.sh \
    && colcon build --packages-skip cyclonedds --cmake-args -DCMAKE_BUILD_TYPE=Release \
    && rm -rf build log

COPY unitree_ros2_setup.sh /opt/unitree_ros2_setup.sh

# Non-root user matching the host UID/GID so build/ install/ in the mounted repo stay owned by you
# (the host render GID is added via compose group_add; name it so `groups` doesn't warn)
RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && (getent group ${RENDER_GID} > /dev/null || groupadd --gid ${RENDER_GID} hostrender) \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && usermod -aG sudo,video,dialout,plugdev ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

RUN { \
        echo 'source /opt/ros/foxy/setup.bash'; \
        echo 'source /opt/cyclonedds_ws/install/setup.bash'; \
        echo 'export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp'; \
        echo '[ -f ~/autonomy_stack_go2/install/setup.bash ] && source ~/autonomy_stack_go2/install/setup.bash'; \
    } >> /home/${USERNAME}/.bashrc

USER ${USERNAME}
WORKDIR /home/${USERNAME}/autonomy_stack_go2
CMD ["bash"]
