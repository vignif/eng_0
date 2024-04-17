# Dockerfile created from instructions in 
# https://github.com/TadasBaltrusaitis/OpenFace/wiki/Unix-Installation

FROM ubuntu:focal

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
    libtbb2 \
    libtbb-dev \
    libjpeg-dev \
    libpng-dev \
    libtiff-dev \
    libdc1394-22-dev \
    unzip \
    wget && \
    rm -rf /var/lib/apt/lists/*

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
COPY mods/FeatureExtraction.cpp exe/FeatureExtraction/FeatureExtraction.cpp
COPY mods/SequenceCapture.cpp lib/local/Utilities/src/SequenceCapture.cpp
COPY mods/SequenceCapture.h lib/local/Utilities/include/SequenceCapture.h

RUN mkdir build && \
    cd build && \
    cmake -D CMAKE_CXX_COMPILER=g++-8 -D CMAKE_C_COMPILER=gcc-8 -D CMAKE_BUILD_TYPE=RELEASE .. && \
    make


# RUN mkdir build

# # Build OpenFace
# RUN cd build && cmake -D CMAKE_BUILD_TYPE=RELEASE .. && make

# # Delete the processed folder
# RUN rm -rf build/processed

# Run FeatureExtraction to preprocess data
# CMD /bin/bash -c "./build/bin/FeatureExtraction -wild -device 0 -pose -gaze -2Dfp -3Dfp"


CMD ["/bin/bash"]
# In another terminal, run python predict.py to execute the prediction
