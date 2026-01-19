#!/bin/bash

# Source logging functions
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source "$SCRIPT_DIR/logging.sh"

info "Installing apt packages..."
# Uncomment and modify below line to install apt packages
# sudo apt install -y --no-install-recommends PACKAGE1 PACKAGE2 || fatal "Failed to install apt packages" 

# For Local Planner (optional)
# sudo apt install -y --no-install-recommends ros-${ROS_DISTRO}-stereo-image-proc ros-${ROS_DISTRO}-image-view || fatal "Failed to install apt packages" 

# QT5 deps for Wayland (only if running on Wayland)
if [ -n "${WAYLAND_DISPLAY}" ]; then
    info "Installing qtwayland5 for Wayland support..."
    sudo apt-get install --no-install-recommends -qq -y qtwayland5 || fatal "Failed to install qtwayland5"
else
    info "Skipping qtwayland5 installation (not running on Wayland)"
fi

# Gstreamer plugins (for Gazebo camera)
#sudo apt-get install --no-install-recommends -qq -y gstreamer1.0-plugins-bad gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly libgstreamer-plugins-base1.0-dev || fatal "Failed to install gstreamer plugins"

# QGroundControl dependencies
#sudo apt-get install --no-install-recommends -qq -y libfuse2 libxcb-xinerama0 libxkbcommon-x11-0 libxcb-cursor-dev || fatal "Failed to install QGroundControl dependencies"

# Install nav2 package
#sudo apt-get install --no-install-recommends -qq -y ros-${ROS_DISTRO}-nav2-bringup ros-${ROS_DISTRO}-navigation2 || fatal "Failed to install nav2 package"

# Install turtlebot3 package
#sudo apt-get install --no-install-recommends -qq -y ros-${ROS_DISTRO}-turtlebot3* || fatal "Failed to install turtlebot3 package"

info "Installing python packages..."
# Uncomment and modify below line to install python packages
# python3 -m pip install PACKAGE1 PACKAGE2 || fatal "Failed to install python packages"
#python3 -m pip install --user -U empy==3.3.4 pyros-genmsg setuptools || fatal "Failed to install python packages"

info "Installing rosdep dependencies..."
rosdep install --from-paths src --ignore-src -y || fatal "Failed to install rosdep dependencies"

info "Dependencies installed successfully"
