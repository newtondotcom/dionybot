# PX4 + ROS2 helper Makefile

translation:
	ros2 run translation_node translation_node_bin

agent:
	MicroXRCEAgent udp4 -p 8888

bridge:
	ros2 launch ros_gz_bridge ros_gz_bridge.launch.py bridge_name:=ros_gz_bridge config_file:=src/dionybot/config/bridge.yml

sim:
	cd Firmware && PX4_GZ_WORLD=bayland make px4_sitl gz_rover_differential

control:
	cd squashfs-root && ./AppRun


clean:
	rm -rf Firmware
	rm -rf src/px4_msgs
	rm -rf src/px4_ros_com
	rm -rf src/px4_msgs_old
	rm -rf src/translation_node
	rm -rf Micro-XRCE-DDS-Agent
	rm -rf squashfs-root

list_topic:
	ros2 topic list

TOPIC ?= /fmu/out/vehicle_status

echo_topic:
	ros2 topic echo $(TOPIC)
