#!/bin/bash

# Source logging functions
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/logging.sh"

$SCRIPT_DIR/update-repos.sh
$SCRIPT_DIR/install-deps.sh

WORKSPACE_PATH=${PWD}
WORKSPACE_SETUP_SCRIPT=${WORKSPACE_PATH}/install/setup.bash

PX4_FIRMWARE_PATH=${WORKSPACE_PATH}/src/Firmware
if [ ! -d "${PX4_FIRMWARE_PATH}" ]; then
    git clone https://github.com/PX4/PX4-Autopilot --recursive "${PX4_FIRMWARE_PATH}" &> /dev/null
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

# Install px4_msgs & px4_ros_com
PX4_MSGS_PATH=${WORKSPACE_PATH}/src/px4_msgs
git clone https://github.com/PX4/px4_msgs.git "${PX4_MSGS_PATH}" &> /dev/null
PX4_ROS_COM_PATH=${WORKSPACE_PATH}/src/px4_ros_com
git clone https://github.com/PX4/px4_ros_com.git "${PX4_ROS_COM_PATH}" &> /dev/null


cd "${WORKSPACE_PATH}"

# Add PX4 ROS 2 Message Translation Node - required above PX4 v1.16
# https://docs.px4.io/main/en/ros2/px4_ros2_msg_translation_node
${PX4_FIRMWARE_PATH}/Tools/copy_to_ros_ws.sh .

## Setup some more Gazebo-related environment variables
info "Setting up .bashrc for PX4 + Gazebo..."

grep -qF 'PX4_GAZEBO_SETUP' "$HOME/.bashrc" || cat << EOF >> "$HOME/.bashrc"
# PX4_GAZEBO_SETUP
if [ -f "\$HOME/src/Firmware/Tools/simulation/gazebo-classic/setup_gazebo.bash" ]; then
  . "\$HOME/src/Firmware/Tools/simulation/gazebo-classic/setup_gazebo.bash" \
    "\$HOME/src/Firmware" \
    "\$HOME/src/Firmware/build/px4_sitl_default"
fi

export GAZEBO_MODEL_PATH="\${GAZEBO_MODEL_PATH}:${WORKSPACE_PATH}/src/avoidance/avoidance/sim/models:${WORKSPACE_PATH}/src/avoidance/avoidance/sim/worlds"
export GAZEBO_MODEL_PATH="\${GAZEBO_MODEL_PATH}:/opt/ros/jazzy/share/turtlebot3_gazebo/models"
export TURTLEBOT3_MODEL=burger
export ROS_PACKAGE_PATH="\${ROS_PACKAGE_PATH}:\$HOME/src/Firmware"
EOF

info "Setting up .bashrc to source ${WORKSPACE_SETUP_SCRIPT}..."
grep -qF 'WORKSPACE_SETUP_SCRIPT' $HOME/.bashrc || echo "source ${WORKSPACE_SETUP_SCRIPT} # WORKSPACE_SETUP_SCRIPT" >> $HOME/.bashrc


# Allow initial setup to complete successfully even if build fails
$SCRIPT_DIR/build.sh || true
