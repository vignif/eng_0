# Dockerfile created from instructions in 
# https://github.com/TadasBaltrusaitis/OpenFace/wiki/Unix-Installation
FROM ros:noetic
# FROM osrf/ros:noetic-desktop-full

LABEL maintainer="Francesco Vigni <vignif@gmail.com>"

# Install essential build tools and dependencies
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    build-essential \
    g++-8 \
    cmake \
    git \
    libopenblas-dev \
    libgtk2.0-dev \
    pkg-config \
    libavcodec-dev \
    libavformat-dev \
    libswscale-dev \
    python-dev \
    python-numpy \
    python3-opencv \
    python3-rosdep \
    python3-catkin-tools \
    libtbb2 \
    libtbb-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libdc1394-22-dev \
    unzip \
    wget \
    ros-noetic-catkin \
    ros-noetic-cv-bridge \
    libyaml-cpp-dev \
    ros-noetic-tf2* \
    && rm -rf /var/lib/apt/lists/*

# Install GCC 8 if not already installed
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 90 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 90

# Install required version of CMake if not available
RUN cmake_version=$(cmake --version | grep -oP "(?<=cmake version )[\d\.]+") && \
    if dpkg --compare-versions "$cmake_version" "lt" "3.8"; then \
        mkdir -p /tmp/cmake_tmp && \
        cd /tmp/cmake_tmp && \
        wget https://cmake.org/files/v3.10/cmake-3.10.1.tar.gz && \
        tar -xzvf cmake-3.10.1.tar.gz -qq && \
        cd cmake-3.10.1/ && \
        ./bootstrap && \
        make -j$(nproc) && \
        make install && \
        cd / && \
        rm -rf /tmp/cmake_tmp; \
    fi

# Download and compile OpenCV 4.1.0
RUN wget https://github.com/opencv/opencv/archive/4.1.0.zip --no-check-certificate && \
    unzip 4.1.0.zip && \
    cd opencv-4.1.0 && \
    mkdir build && \
    cd build && \
    cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D BUILD_TIFF=ON -D WITH_TBB=ON .. && \
    make -j$(nproc) && \
    make install && \
    cd / && \
    rm -rf opencv-4.1.0 4.1.0.zip

# Download and compile dlib
RUN wget http://dlib.net/files/dlib-19.13.tar.bz2 && \
    tar xf dlib-19.13.tar.bz2 && \
    cd dlib-19.13 && \
    mkdir build && \
    cd build && \
    cmake .. && \
    cmake --build . --config Release && \
    make install && \
    ldconfig && \
    cd / && \
    rm -rf dlib-19.13 dlib-19.13.tar.bz2

# Install Boost (optional)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libboost-all-dev && \
    rm -rf /var/lib/apt/lists/*

# Clone OpenFace repository
#RUN git clone https://github.com/TadasBaltrusaitis/OpenFace.git
COPY /OpenFace /OpenFace
# Create build directory for OpenFace and compile
WORKDIR /OpenFace
# Replace the necessary files

## THIS IS DONE DIRECTLY IN THE HOST FOLDER ##
# COPY mods/FeatureExtraction.cpp exe/FeatureExtraction/FeatureExtraction.cpp
# COPY mods/SequenceCapture.cpp lib/local/Utilities/src/SequenceCapture.cpp
# COPY mods/SequenceCapture.h lib/local/Utilities/include/SequenceCapture.h

RUN mkdir build && \
    cd build && \
    cmake \
        -DCMAKE_CXX_COMPILER=g++-8 \
        -DCMAKE_C_COMPILER=gcc-8 \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        .. && \
    make -j$(nproc) && \
    make install

RUN chmod +x ./download_models.sh

RUN ./download_models.sh

WORKDIR /

COPY /catkin_ws /catkin_ws

WORKDIR /catkin_ws

# Set Git access token as an environment variable
ENV GIT_ACCESS_TOKEN
RUN git clone https://${GIT_ACCESS_TOKEN}@github.com/vignif/grace_common_msgs.git /catkin_ws/src/grace_common_msgs


RUN /bin/bash -c "source /opt/ros/noetic/setup.bash"

RUN /bin/bash -c "pwd"

# RUN source /opt/ros/noetic/setup.bash
# RUN catkin build

COPY README.md /catkin_ws/


COPY entrypoint.sh /entrypoint.sh

# Make the entrypoint script executable
RUN chmod +x /entrypoint.sh

RUN /entrypoint.sh

CMD [ "/bin/bash" ]

# Set the entrypoint to run the entrypoint script
# ENTRYPOINT ["/entrypoint.sh"]


