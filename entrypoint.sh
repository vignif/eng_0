#!/bin/bash
# apt-get update

pwd

source /opt/ros/noetic/setup.bash

catkin build

source devel/setup.bash

# rosrun openface2_ros openface2_ros_single _image_topic:=/naoqi_driver_node/camera/front/image_raw

# Keep the container running
# exec "$@"




