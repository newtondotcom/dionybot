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
export GAZEBO_MODEL_PATH="\${GAZEBO_MODEL_PATH}:/opt/ros/kilted/share/turtlebot3_gazebo/models"
export TURTLEBOT3_MODEL=burger
export ROS_PACKAGE_PATH="\${ROS_PACKAGE_PATH}:\$HOME/Firmware"
EOF

info "Setting up .bashrc to source ${WORKSPACE_SETUP_SCRIPT}..."
grep -qF 'WORKSPACE_SETUP_SCRIPT' $HOME/.bashrc || echo "source ${WORKSPACE_SETUP_SCRIPT} # WORKSPACE_SETUP_SCRIPT" >> $HOME/.bashrc


# Allow initial setup to complete successfully even if build fails
cd "${WORKSPACE_PATH}"
$SCRIPT_DIR/build.sh || true
