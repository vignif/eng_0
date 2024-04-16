# Use an appropriate base image
FROM ubuntu:focal

ENV DEBIAN_FRONTEND noninteractive

# RUN apt-get clean
# Install necessary dependencies


RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -qq install -y \
    # tcl \
    git \
    cmake \
    build-essential \
    libopencv-dev \
    # libboost-all-dev \
    # libtbb-dev \
    # python3 \
    # python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Clone OpenFace repository
RUN git clone https://github.com/TadasBaltrusaitis/OpenFace.git

# Navigate to OpenFace directory
WORKDIR /OpenFace

# Replace the necessary files
COPY mods/FeatureExtraction.cpp exe/FeatureExtraction/FeatureExtraction.cpp
COPY mods/SequenceCapture.cpp lib/local/Utilities/src/SequenceCapture.cpp
COPY mods/SequenceCapture.h lib/local/Utilities/include/SequenceCapture.h

# Build OpenFace
RUN cd build && cmake -D CMAKE_BUILD_TYPE=RELEASE .. && make

# Delete the processed folder
RUN rm -rf build/processed

# Run FeatureExtraction to preprocess data
CMD /bin/bash -c "./build/bin/FeatureExtraction -wild -device 0 -pose -gaze -2Dfp -3Dfp"

# In another terminal, run python predict.py to execute the prediction
