#!/bin/bash

# Source logging functions
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/logging.sh"

info "Installing apt packages..."
# Uncomment and modify below line to install apt packages
# sudo apt install -y --no-install-recommends PACKAGE1 PACKAGE2 || fatal "Failed to install apt packages" 

# For Local Planner (optional)
# sudo apt install -y --no-install-recommends ros-${ROS_DISTRO}-stereo-image-proc ros-${ROS_DISTRO}-image-view || fatal "Failed to install apt packages" 

# Gstreamer plugins (for Gazebo camera)
sudo apt-get install --no-install-recommends -y gstreamer1.0-plugins-bad gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly libgstreamer-plugins-base1.0-dev || fatal "Failed to install gstreamer plugins"

info "Installing python packages..."
# Uncomment and modify below line to install python packages
# python3 -m pip install PACKAGE1 PACKAGE2 || fatal "Failed to install python packages"

info "Installing rosdep dependencies..."
rosdep install --from-paths src --ignore-src -y || fatal "Failed to install rosdep dependencies"

info "Dependencies installed successfully"
