#!/bin/bash

# Source logging functions
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/logging.sh"

$SCRIPT_DIR/update-repos.sh
$SCRIPT_DIR/install-deps.sh

WORKSPACE_PATH=${PWD}
WORKSPACE_SETUP_SCRIPT=${WORKSPACE_PATH}/install/setup.bash

PX4_FIRMWARE_PATH=${WORKSPACE_PATH}/Firmware
if [ ! -d "${PX4_FIRMWARE_PATH}" ]; then
    git clone https://github.com/PX4/PX4-Autopilot --recursive "${PX4_FIRMWARE_PATH}" &> /dev/null
else
    cd "${PX4_FIRMWARE_PATH}"
    git pull
fi
cd "${PX4_FIRMWARE_PATH}"
# Ensure USER is set for PX4 setup script (it uses /home/$USER/.bashrc)
export USER=${USER:-$(whoami)}
./Tools/setup/ubuntu.sh 
# --no-sim-tools --no-nuttx

## This is necessary to prevent some Qt-related errors (feel free to try to omit it)
# export QT_X11_NO_MITSHM=1

## Build PX4 Firmware along with the workspace
info "Building PX4 Firmware..."
#DONT_RUN=1 make px4_sitl gz_rover_differential
make px4_sitl

# Install Micro XRCE-DDS Agent & Client for PX4
XRCEDDS_AGENT_PATH=${WORKSPACE_PATH}/Micro-XRCE-DDS-Agent
git clone -b v2.4.3 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git "${XRCEDDS_AGENT_PATH}" &> /dev/null
cd "${XRCEDDS_AGENT_PATH}"
mkdir build
cd build
cmake ..
make
sudo make install
sudo ldconfig /usr/local/lib/

# Install px4_msgs & px4_ros_com & ros_gz
PX4_MSGS_PATH=${WORKSPACE_PATH}/src/px4_msgs
if [ ! -d "${PX4_MSGS_PATH}" ]; then
git clone https://github.com/PX4/px4_msgs.git "${PX4_MSGS_PATH}" &> /dev/null
else
    cd "${PX4_MSGS_PATH}"
    git pull
fi
PX4_ROS_COM_PATH=${WORKSPACE_PATH}/src/px4_ros_com
if [ ! -d "${PX4_ROS_COM_PATH}" ]; then
git clone https://github.com/PX4/px4_ros_com.git "${PX4_ROS_COM_PATH}" &> /dev/null
else
    cd "${PX4_ROS_COM_PATH}"
    git pull
fi
#ROS_GZ_PATH=${WORKSPACE_PATH}/src/ros_gz
#if [ ! -d "${ROS_GZ_PATH}" ]; then
#git clone https://github.com/gazebosim/ros_gz.git -b jazzy "${ROS_GZ_PATH}" &> /dev/null
#else
#    cd "${ROS_GZ_PATH}"
#    git pull
#fi

cd "${WORKSPACE_PATH}"

# Download QGroundControl AppImage if not already present
if [ ! -f "${WORKSPACE_PATH}/QGroundControl-x86_64.AppImage" ]; then
    info "Downloading QGroundControl..."
    wget https://github.com/mavlink/qgroundcontrol/releases/download/v5.0.8/QGroundControl-x86_64.AppImage -P ${WORKSPACE_PATH}/ \
        && chmod +x ${WORKSPACE_PATH}/QGroundControl-x86_64.AppImage
    ${WORKSPACE_PATH}/QGroundControl-x86_64.AppImage --appimage-extract
fi

# Add PX4 ROS 2 Message Translation Node - required above PX4 v1.16
# https://docs.px4.io/main/en/ros2/px4_ros2_msg_translation_node
${PX4_FIRMWARE_PATH}/Tools/copy_to_ros_ws.sh .

# Copy custom models to PX4 Gazebo models folder
cp -r ${WORKSPACE_PATH}/src/dionybot/model/dionybot ${PX4_FIRMWARE_PATH}/Tools/simulation/gz/models/ \
    #&& cp -r ${WORKSPACE_PATH}/src/dionybot/model/OakD-Lite ${PX4_FIRMWARE_PATH}/Tools/simulation/gz/models/ \
    #&& cp -r ${WORKSPACE_PATH}/src/dionybot/model/turtlebot3_world ${PX4_FIRMWARE_PATH}/Tools/simulation/gz/models/ \
    # && cp -r ${WORKSPACE_PATH}/src/dionybot/model/lidar_2d_v2 ${PX4_FIRMWARE_PATH}/Tools/simulation/gz/models/
#cp ${WORKSPACE_PATH}/src/rtabmap_nav2_px4/world/turtlebot3_world.sdf ${PX4_FIRMWARE_PATH}/Tools/simulation/gz/worlds/

cp ${WORKSPACE_PATH}/src/dionybot/config/50001_gz_dionybot ${PX4_FIRMWARE_PATH}/ROMFS/px4fmu_common/init.d-posix/airframes/
chmod +x ${PX4_FIRMWARE_PATH}/ROMFS/px4fmu_common/init.d-posix/airframes/50001_dionybot
# add 50001_dionybot in CMakeLists.txt
sed -i '/50000_gz_rover_differential/a\    50001_gz_dionybot' /home/ubuntu/PX4-Autopilot/ROMFS/px4fmu_common/init.d-posix/airframes/CMakeLists.txt
  
## Setup some more Gazebo-related environment variables
info "Setting up .bashrc for PX4 + Gazebo..."

grep -qF 'PX4_GAZEBO_SETUP' "$HOME/.bashrc" || cat << EOF >> "$HOME/.bashrc"
# PX4_GAZEBO_SETUP
if [ -f "\$HOME/Firmware/Tools/simulation/gazebo-classic/setup_gazebo.bash" ]; then
  . "\$HOME/Firmware/Tools/simulation/gazebo-classic/setup_gazebo.bash" \
    "\$HOME/Firmware" \
    "\$HOME/Firmware/build/px4_sitl_default"
fi

export GAZEBO_MODEL_PATH="\${GAZEBO_MODEL_PATH}:${WORKSPACE_PATH}/src/avoidance/avoidance/sim/models:${WORKSPACE_PATH}/src/avoidance/avoidance/sim/worlds"
export GAZEBO_MODEL_PATH="\${GAZEBO_MODEL_PATH}:/opt/ros/jazzy/share/turtlebot3_gazebo/models"
export TURTLEBOT3_MODEL=burger
export ROS_PACKAGE_PATH="\${ROS_PACKAGE_PATH}:\$HOME/Firmware"
EOF

info "Setting up .bashrc to source ${WORKSPACE_SETUP_SCRIPT}..."
grep -qF 'WORKSPACE_SETUP_SCRIPT' $HOME/.bashrc || echo "source ${WORKSPACE_SETUP_SCRIPT} # WORKSPACE_SETUP_SCRIPT" >> $HOME/.bashrc


# Allow initial setup to complete successfully even if build fails
$SCRIPT_DIR/build.sh || true
