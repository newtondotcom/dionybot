# PX4 + ROS2 helper Makefile

translation:
	ros2 run translation_node translation_node_bin

agent:
	MicroXRCEAgent udp4 -p 8888

sim:
	cd src/Firmware && make px4_sitl gz_rover_differential

clean:
	rm -rf src/Firmware
	rm -rf src/px4_msgs
	rm -rf src/px4_ros_com
	rm -rf src/px4_msgs_old
	rm -rf src/translation_node
