#!/bin/bash

# Source logging functions
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/logging.sh"

$SCRIPT_DIR/update-repos.sh
$SCRIPT_DIR/install-deps.sh

WORKSPACE_PATH=${PWD}
WORKSPACE_SETUP_SCRIPT=${WORKSPACE_PATH}/install/setup.bash

# PX4 and Gazebo related setup
## This is necessary to prevent some Qt-related errors (feel free to try to omit it)
export QT_X11_NO_MITSHM=1

## Build PX4 Firmware along with the workspace
info "Building PX4 Firmware..."
DONT_RUN=1 make px4_sitl_default gazebo

## Setup some more Gazebo-related environment variables
info "Setting up .bashrc for PX4 + Gazebo..."

grep -qF 'PX4_GAZEBO_SETUP' "$HOME/.bashrc" || cat << 'EOF' >> "$HOME/.bashrc"
# PX4_GAZEBO_SETUP
if [ -f "$HOME/Firmware/Tools/simulation/gazebo-classic/setup_gazebo.bash" ]; then
  . "$HOME/Firmware/Tools/simulation/gazebo-classic/setup_gazebo.bash" \
    "$HOME/Firmware" \
    "$HOME/Firmware/build/px4_sitl_default"
fi

export GAZEBO_MODEL_PATH="${GAZEBO_MODEL_PATH}:/ABSOLUTE/PATH/TO/YOUR/WORKSPACE/src/avoidance/avoidance/sim/models:/ABSOLUTE/PATH/TO/YOUR/WORKSPACE/src/avoidance/avoidance/sim/worlds"
export ROS_PACKAGE_PATH="${ROS_PACKAGE_PATH}:$HOME/Firmware"
# PX4_GAZEBO_SETUP
EOF

info "Setting up .bashrc to source ${WORKSPACE_SETUP_SCRIPT}..."
grep -qF 'WORKSPACE_SETUP_SCRIPT' $HOME/.bashrc || echo "source ${WORKSPACE_SETUP_SCRIPT} # WORKSPACE_SETUP_SCRIPT" >> $HOME/.bashrc


# Allow initial setup to complete successfully even if build fails
$SCRIPT_DIR/build.sh || true
